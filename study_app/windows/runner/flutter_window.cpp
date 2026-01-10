#include "flutter_window.h"

#include <optional>

#include <commctrl.h>
#include <windowsx.h>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetupPenChannel();
  auto child = flutter_controller_->view()->GetNativeWindow();
  SetChildContent(child);
  InstallChildSubclass(child);

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  RemoveChildSubclass();
  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  HandlePointerMessage(hwnd, message, wparam, lparam);

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::InstallChildSubclass(HWND child) {
  if (child == nullptr) {
    return;
  }
  child_content_handle_ = child;
  SetWindowSubclass(child_content_handle_, PenSubclassProc, 1,
                    reinterpret_cast<DWORD_PTR>(this));
}

void FlutterWindow::RemoveChildSubclass() {
  if (child_content_handle_ == nullptr) {
    return;
  }
  RemoveWindowSubclass(child_content_handle_, PenSubclassProc, 1);
  child_content_handle_ = nullptr;
}

LRESULT CALLBACK FlutterWindow::PenSubclassProc(HWND hwnd, UINT message,
                                                WPARAM wparam, LPARAM lparam,
                                                UINT_PTR /*subclass_id*/,
                                                DWORD_PTR ref_data) noexcept {
  auto* window = reinterpret_cast<FlutterWindow*>(ref_data);
  if (window) {
    window->HandlePointerMessage(hwnd, message, wparam, lparam);
  }
  return DefSubclassProc(hwnd, message, wparam, lparam);
}

void FlutterWindow::SetupPenChannel() {
  if (!flutter_controller_ || !flutter_controller_->engine()) {
    return;
  }
  pen_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "study_app/windows_pen",
          &flutter::StandardMethodCodec::GetInstance());
}

void FlutterWindow::SendPenEvent(const flutter::EncodableMap& event) {
  if (!pen_channel_) {
    return;
  }
  pen_channel_->InvokeMethod(
      "penEvent",
      std::make_unique<flutter::EncodableValue>(event));
}

void FlutterWindow::HandlePointerMessage(HWND window, UINT const message,
                                         WPARAM const wparam,
                                         LPARAM const lparam) noexcept {
  if (message != WM_POINTERDOWN && message != WM_POINTERUPDATE &&
      message != WM_POINTERUP && message != WM_POINTERCAPTURECHANGED) {
    return;
  }

  const UINT32 pointer_id = GET_POINTERID_WPARAM(wparam);
  POINTER_INPUT_TYPE pointer_type = PT_POINTER;
  if (!GetPointerType(pointer_id, &pointer_type)) {
    return;
  }
  if (pointer_type != PT_PEN) {
    return;
  }

  POINTER_PEN_INFO pen_info;
  if (!GetPointerPenInfo(pointer_id, &pen_info)) {
    return;
  }

  POINT point = pen_info.pointerInfo.ptPixelLocation;
  if (!ScreenToClient(window, &point)) {
    return;
  }

  const double dpi_scale = static_cast<double>(GetDpiForWindow(window)) / 96.0;
  const double x = point.x / dpi_scale;
  const double y = point.y / dpi_scale;
  const double pressure = pen_info.pressure / 1024.0;
  const bool eraser =
      (pen_info.penFlags & PEN_FLAG_ERASER) == PEN_FLAG_ERASER;

  const char* type = "move";
  if (message == WM_POINTERDOWN) {
    type = "down";
  } else if (message == WM_POINTERUP) {
    type = "up";
  } else if (message == WM_POINTERCAPTURECHANGED) {
    type = "cancel";
  }

  flutter::EncodableMap event;
  event[flutter::EncodableValue("type")] = flutter::EncodableValue(type);
  event[flutter::EncodableValue("pointer")] =
      flutter::EncodableValue(static_cast<int>(pointer_id));
  event[flutter::EncodableValue("x")] = flutter::EncodableValue(x);
  event[flutter::EncodableValue("y")] = flutter::EncodableValue(y);
  event[flutter::EncodableValue("pressure")] =
      flutter::EncodableValue(pressure);
  event[flutter::EncodableValue("eraser")] =
      flutter::EncodableValue(eraser);
  SendPenEvent(event);
}

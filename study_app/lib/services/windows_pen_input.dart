import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class WindowsPenEvent {
  final String type;
  final int pointer;
  final double x;
  final double y;
  final double pressure;
  final bool eraser;

  const WindowsPenEvent({
    required this.type,
    required this.pointer,
    required this.x,
    required this.y,
    required this.pressure,
    required this.eraser,
  });

  static WindowsPenEvent? fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return null;
    final type = map['type'] as String?;
    final pointer = map['pointer'];
    final x = map['x'];
    final y = map['y'];
    final pressure = map['pressure'];
    final eraser = map['eraser'];
    if (type == null ||
        pointer is! int ||
        x is! num ||
        y is! num ||
        pressure is! num ||
        eraser is! bool) {
      return null;
    }
    return WindowsPenEvent(
      type: type,
      pointer: pointer,
      x: x.toDouble(),
      y: y.toDouble(),
      pressure: pressure.toDouble(),
      eraser: eraser,
    );
  }
}

class WindowsPenInput {
  static const MethodChannel _channel = MethodChannel('study_app/windows_pen');
  static final WindowsPenInput instance = WindowsPenInput._();
  final StreamController<WindowsPenEvent> _controller =
      StreamController<WindowsPenEvent>.broadcast();
  bool _initialized = false;

  WindowsPenInput._();

  Stream<WindowsPenEvent> get events {
    if (!Platform.isWindows) {
      return const Stream<WindowsPenEvent>.empty();
    }
    if (!_initialized) {
      _initialized = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'penEvent') return;
        final map = call.arguments as Map<dynamic, dynamic>?;
        final event = WindowsPenEvent.fromMap(map);
        if (event != null) {
          _controller.add(event);
        }
      });
    }
    return _controller.stream;
  }
}

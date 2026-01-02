import 'dart:async';

import 'package:flutter/material.dart';

import '../models/teach_settings.dart';
import '../services/teach_service.dart';

class TeachModePageScreen extends StatefulWidget {
  const TeachModePageScreen({super.key});

  @override
  State<TeachModePageScreen> createState() => _TeachModePageScreenState();
}

class _TeachModePageScreenState extends State<TeachModePageScreen> {
  TeachSettings? settings;
  bool loading = true;
  bool busy = false;
  bool downloading = false;
  double downloadProgress = 0;
  LocalModelInfo? selectedModel;
  bool modelInstalled = false;
  Timer? _saveTimer;

  final topicCtrl = TextEditingController();
  final audienceCtrl = TextEditingController(text: "peer");
  final explanationCtrl = TextEditingController();
  final apiKeyCtrl = TextEditingController();
  final cloudModelCtrl = TextEditingController(text: "gpt-4o-mini");
  final cloudEndpointCtrl = TextEditingController();
  String critique = "";

  @override
  void initState() {
    super.initState();
    _attachAutosaveListeners();
    _load();
  }

  @override
  void dispose() {
    topicCtrl.dispose();
    audienceCtrl.dispose();
    explanationCtrl.dispose();
    apiKeyCtrl.dispose();
    cloudModelCtrl.dispose();
    cloudEndpointCtrl.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  void _attachAutosaveListeners() {
    for (final ctrl in [apiKeyCtrl, cloudModelCtrl, cloudEndpointCtrl]) {
      ctrl.addListener(_scheduleSave);
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _saveSettings();
    });
  }

  Future<void> _load() async {
    final s = await teachService.loadSettings();
    if (s.cloudProvider.isEmpty) s.cloudProvider = 'openai';
    if (s.cloudModel.isEmpty) s.cloudModel = 'gpt-4o-mini';
    apiKeyCtrl.text = s.apiKey ?? "";
    cloudModelCtrl.text = s.cloudModel;
    cloudEndpointCtrl.text = s.cloudEndpoint;
    // pick first model as default
    final defaultModel = availableLocalModels.first;
    final installed = await teachService.modelManager.isInstalled(defaultModel);
    if (!mounted) return;
    setState(() {
      settings = s;
      loading = false;
      selectedModel = defaultModel;
      modelInstalled = installed;
    });
  }

  Future<void> _saveSettings() async {
    final s = settings;
    if (s == null) return;
    s.apiKey = apiKeyCtrl.text.trim();
    s.cloudModel = cloudModelCtrl.text.trim().isEmpty ? s.cloudModel : cloudModelCtrl.text.trim();
    s.cloudEndpoint = cloudEndpointCtrl.text.trim();
    await teachService.saveSettings(s);
    setState(() {});
  }

  Future<void> _runCritique() async {
    if (busy || settings == null) return;
    if (settings!.provider == 'local') {
      setState(() {
        critique = "Local LLM is under development. Please switch to Cloud to continue.";
      });
      return;
    }
    final topic = topicCtrl.text.trim();
    final audience = audienceCtrl.text.trim().isEmpty ? "peer" : audienceCtrl.text.trim();
    final explanation = explanationCtrl.text.trim();
    if (topic.isEmpty || explanation.isEmpty) return;
    setState(() {
      busy = true;
      critique = "";
    });
    try {
      if (settings!.provider == 'cloud') {
        final key = apiKeyCtrl.text.trim();
        if (key.isEmpty) {
          critique = "Please enter an API key.";
        } else {
          final model = cloudModelCtrl.text.trim().isEmpty ? settings!.cloudModel : cloudModelCtrl.text.trim();
          critique = await teachService.critiqueCloud(
            provider: settings!.cloudProvider,
            apiKey: key,
            model: model,
            endpointOverride: cloudEndpointCtrl.text.trim().isEmpty ? null : cloudEndpointCtrl.text.trim(),
            topic: topic,
            explanation: explanation,
            audience: audience,
          );
        }
      } else {
        critique = await teachService.critiqueLocally(
          topic: topic,
          audience: audience,
          explanation: explanation,
          modelId: selectedModel?.id,
        );
      }
    } catch (e) {
      critique = "Failed to get critique: $e";
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (loading || settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Teach Mode"),
        actions: [
          IconButton(
            tooltip: "Save settings",
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AI Provider", style: textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _providerToggle(colors, textTheme),
                  const SizedBox(height: 12),
                  if (settings!.provider == 'local') _localModelPanel(colors, textTheme),
                  if (settings!.provider == 'cloud') _cloudPanel(colors, textTheme),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text("Explain the concept", style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: topicCtrl,
                    decoration: const InputDecoration(labelText: "Topic / concept"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: audienceCtrl,
                    decoration: const InputDecoration(labelText: "Audience (e.g., peer, beginner)"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: explanationCtrl,
                    minLines: 6,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: "Your explanation",
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _runCritique,
                      icon: busy
                          ? SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(busy ? "Working..." : "Get critique"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.outline),
                      ),
                      child: critique.isEmpty
                          ? Text(
                              "Your feedback will appear here.",
                              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                            )
                          : SingleChildScrollView(
                              child: Text(
                                critique,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _providerToggle(ColorScheme colors, TextTheme textTheme) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'local', label: Text("Local")),
        ButtonSegment(value: 'cloud', label: Text("Cloud")),
      ],
      selected: {settings!.provider},
      onSelectionChanged: (sel) {
        settings = (settings ?? TeachSettings())..provider = sel.first;
        setState(() {});
        _scheduleSave();
      },
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      ),
    );
  }

  Widget _localModelPanel(ColorScheme colors, TextTheme textTheme) {
    final model = selectedModel ?? availableLocalModels.first;
    return Stack(
      children: [
        Opacity(
          opacity: 0.35,
          child: IgnorePointer(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Local models", style: textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(model.name, style: textTheme.bodyMedium),
                      const Spacer(),
                      Text("${(model.sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB",
                          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (downloading) ...[
                    LinearProgressIndicator(value: downloadProgress),
                    const SizedBox(height: 6),
                    Text("Downloading... ${(downloadProgress * 100).toStringAsFixed(0)}%",
                        style: textTheme.bodySmall),
                  ] else if (modelInstalled) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 6),
                        Text("Installed", style: textTheme.bodySmall),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Remove"),
                        ),
                      ],
                    )
                  ] else ...[
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text("Download & use"),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Downloads to app storage for offline use.",
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outline),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock, color: colors.primary),
                const SizedBox(height: 8),
                Text(
                  "Local LLM is in development",
                  style: textTheme.titleSmall?.copyWith(color: colors.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "Please use the Cloud provider for now.",
                  style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      settings = (settings ?? TeachSettings())..provider = 'cloud';
                    });
                    _scheduleSave();
                  },
                  icon: const Icon(Icons.cloud_outlined),
                  label: const Text("Switch to Cloud"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cloudPlaceholder(ColorScheme colors, TextTheme textTheme) {
    return const SizedBox.shrink();
  }

  Widget _cloudPanel(ColorScheme colors, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Cloud settings", style: textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: settings!.cloudProvider,
            items: const [
              DropdownMenuItem(value: 'openai', child: Text("OpenAI-compatible")),
              DropdownMenuItem(value: 'anthropic', child: Text("Anthropic")),
            ],
            onChanged: (val) {
              if (val == null) return;
              settings = (settings ?? TeachSettings())..cloudProvider = val;
              setState(() {});
              _scheduleSave();
            },
            decoration: const InputDecoration(labelText: "Provider"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: apiKeyCtrl,
            decoration: const InputDecoration(
              labelText: "API key",
              hintText: "sk-...",
            ),
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: cloudModelCtrl,
            decoration: const InputDecoration(
              labelText: "Model",
              hintText: "e.g. gpt-4o-mini / claude-3-5-sonnet-20240620",
            ),
          ),
          const SizedBox(height: 10),
          if (settings!.cloudProvider == 'openai')
            TextField(
              controller: cloudEndpointCtrl,
              decoration: const InputDecoration(
                labelText: "Custom endpoint (optional)",
                hintText: "https://your-proxy/v1/chat/completions",
              ),
              enableSuggestions: false,
              autocorrect: false,
            ),
          const SizedBox(height: 10),
          Text(
            "Your key stays on device. We do not collect or store it remotely.",
            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

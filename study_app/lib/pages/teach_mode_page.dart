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

  final topicCtrl = TextEditingController();
  final audienceCtrl = TextEditingController(text: "peer");
  final explanationCtrl = TextEditingController();
  String critique = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await teachService.loadSettings();
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
    await teachService.saveSettings(s);
    setState(() {});
  }

  Future<void> _runCritique() async {
    if (busy || settings == null) return;
    if (settings!.provider == 'local' && !modelInstalled) return;
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
        critique = "Cloud critique placeholder. Connect your API later.";
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
                  if (settings!.provider == 'cloud') _cloudPlaceholder(colors, textTheme),
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
      },
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      ),
    );
  }

  Widget _localModelPanel(ColorScheme colors, TextTheme textTheme) {
    final model = selectedModel ?? availableLocalModels.first;
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
                  onPressed: () async {
                    await teachService.modelManager.remove(model);
                    final installed = await teachService.modelManager.isInstalled(model);
                    if (!mounted) return;
                    setState(() {
                      modelInstalled = installed;
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Remove"),
                ),
              ],
            )
          ] else ...[
            FilledButton.icon(
              onPressed: () async {
                setState(() {
                  downloading = true;
                  downloadProgress = 0;
                });
                try {
                  await teachService.modelManager.download(model, (p) {
                    if (mounted) {
                      setState(() => downloadProgress = p);
                    }
                  });
                  final installed = await teachService.modelManager.isInstalled(model);
                  if (!mounted) return;
                  setState(() {
                    modelInstalled = installed;
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("Download failed: $e")));
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      downloading = false;
                      downloadProgress = 0;
                    });
                  }
                }
              },
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
    );
  }

  Widget _cloudPlaceholder(ColorScheme colors, TextTheme textTheme) {
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
          Text("Cloud (coming soon)", style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            "Hook up your API/subscription here later. Currently a placeholder.",
            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

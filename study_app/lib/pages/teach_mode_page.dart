import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/teach_settings.dart';
import '../services/teach_service.dart';
import '../services/local_llm_service.dart';
import 'settings_page.dart';

class TeachModePageScreen extends StatefulWidget {
  const TeachModePageScreen({super.key});

  @override
  State<TeachModePageScreen> createState() => _TeachModePageScreenState();
}

class _TeachModePageScreenState extends State<TeachModePageScreen> {
  TeachSettings? settings;
  bool loading = true;
  bool busy = false;
  String critique = "";

  final topicCtrl = TextEditingController();
  final audienceCtrl = TextEditingController(text: "peer");
  final explanationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    topicCtrl.dispose();
    audienceCtrl.dispose();
    explanationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await teachService.loadSettings();
    if (!mounted) return;
    setState(() {
      settings = s;
      loading = false;
    });
  }

  Future<void> _runCritique() async {
    if (busy || settings == null) return;
    final topic = topicCtrl.text.trim();
    final audience = audienceCtrl.text.trim().isEmpty ? "peer" : audienceCtrl.text.trim();
    final explanation = explanationCtrl.text.trim();
    if (topic.isEmpty || explanation.isEmpty) return;

    final useLocal = settings!.useLocalLLM;
    final apiKey = settings!.apiKey?.trim() ?? "";

    // Check if using cloud and no API key
    if (!useLocal && apiKey.isEmpty) {
      setState(() {
        critique = "Add an API key in Settings > AI to use cloud critique, or enable Local LLM mode.";
      });
      return;
    }

    // Check if using local LLM and it's available
    if (useLocal) {
      final selectedModel = await localLLMService.getSelectedModel();
      if (selectedModel == null) {
        setState(() {
          critique = "No local model selected. Please download and select a model in Settings > AI.";
        });
        return;
      }
    }

    setState(() {
      busy = true;
      critique = "";
    });
    try {
      final model = settings!.cloudModel.isEmpty ? "gpt-4o-mini" : settings!.cloudModel;
      critique = await teachService.critique(
        provider: settings!.cloudProvider.isEmpty ? 'openai' : settings!.cloudProvider,
        apiKey: apiKey,
        model: model,
        endpointOverride: settings!.cloudEndpoint.isEmpty ? null : settings!.cloudEndpoint,
        topic: topic,
        explanation: explanation,
        audience: audience,
        useLocalLLM: useLocal,
      );
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

    final hasApiKey = (settings!.apiKey ?? '').trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teach Mode"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: _settingsSummaryCard(textTheme, colors, hasApiKey),
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
                          ? Center(
                              child: Text(
                                "Output will appear here.",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Markdown(
                              data: critique,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: textTheme.bodyMedium,
                                h1: textTheme.headlineSmall,
                                h2: textTheme.titleLarge,
                                h3: textTheme.titleMedium,
                                strong: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                listBullet: textTheme.bodyMedium,
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

  Widget _settingsSummaryCard(TextTheme textTheme, ColorScheme colors, bool hasApiKey) {
    final useLocal = settings!.useLocalLLM;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AI Settings", style: textTheme.titleSmall),
          const SizedBox(height: 8),

          // Show mode (Local or Cloud)
          Row(
            children: [
              Icon(
                useLocal ? Icons.computer : Icons.cloud,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                useLocal ? "Local LLM" : "Cloud AI",
                style: textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Show appropriate details based on mode
          if (useLocal) ...[
            FutureBuilder<String?>(
              future: localLLMService.getSelectedModel(),
              builder: (context, snapshot) {
                final model = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryRow("Model", model ?? "None selected"),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          model != null ? Icons.check_circle : Icons.error_outline,
                          color: model != null ? Colors.green : colors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            model != null ? "Model ready" : "No model selected",
                            style: textTheme.bodySmall?.copyWith(
                              color: model != null ? colors.onSurfaceVariant : colors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            _summaryRow("Provider", settings!.cloudProvider.isEmpty ? "openai" : settings!.cloudProvider),
            _summaryRow("Model", settings!.cloudModel.isEmpty ? "gpt-4o-mini" : settings!.cloudModel),
            if (settings!.cloudEndpoint.isNotEmpty)
              _summaryRow("Endpoint", settings!.cloudEndpoint),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  hasApiKey ? Icons.verified_user : Icons.error_outline,
                  color: hasApiKey ? Colors.green : colors.error,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasApiKey ? "API key configured" : "No API key set",
                    style: textTheme.bodySmall?.copyWith(
                      color: hasApiKey ? colors.onSurfaceVariant : colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
            icon: const Icon(Icons.settings),
            label: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: "),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

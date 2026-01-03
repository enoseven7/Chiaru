import 'package:flutter/material.dart';

import '../services/export_service.dart';
import '../services/settings_service.dart';
import '../services/teach_service.dart';
import '../models/teach_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _exporting = false;
  bool _teachLoading = true;
  TeachSettings? _teachSettings;
  final _aiKeyCtrl = TextEditingController();
  final _aiModelCtrl = TextEditingController(text: "gpt-4o-mini");
  final _aiEndpointCtrl = TextEditingController();
  String _aiProvider = 'openai';

  @override
  void initState() {
    super.initState();
    _loadTeachSettings();
  }

  @override
  void dispose() {
    _aiKeyCtrl.dispose();
    _aiModelCtrl.dispose();
    _aiEndpointCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<AppSettings>(
          valueListenable: appSettingsNotifier,
          builder: (context, settings, _) {
            return ListView(
              children: [
                _sectionHeader(textTheme, "Data"),
                _card(
                  context,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Export data", style: textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              "Download your notes, flashcards, quizzes, and planner tasks as JSON.",
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _exporting ? null : () => _exportData(context),
                        child: _exporting
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Export"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionHeader(textTheme, "Appearance"),
                _card(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Presets", style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ThemePreset.values.map((preset) {
                          return ChoiceChip(
                            label: Text(preset.name),
                            selected: settings.preset == preset,
                            onSelected: (_) => _applyPreset(preset, settings),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text("Base brightness", style: textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text("Light"),
                            selected: settings.brightness == Brightness.light,
                            onSelected: (_) => _updateSettings(
                              settings.copyWith(
                                brightness: Brightness.light,
                                preset: ThemePreset.custom,
                              ),
                            ),
                          ),
                          ChoiceChip(
                            label: const Text("Dark"),
                            selected: settings.brightness == Brightness.dark,
                            onSelected: (_) => _updateSettings(
                              settings.copyWith(
                                brightness: Brightness.dark,
                                preset: ThemePreset.custom,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text("Gradient surfaces", style: textTheme.titleMedium),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Use gradients on surfaces"),
                        subtitle: const Text("Blend surface background using two colors."),
                        value: settings.useGradient,
                        onChanged: (val) =>
                            _updateSettings(settings.copyWith(useGradient: val, preset: ThemePreset.custom)),
                      ),
                      const SizedBox(height: 12),
                      Text("Colors", style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _colorRow("Primary", settings.primary, (c) {
                        _updateSettings(
                          settings.copyWith(primary: c, preset: ThemePreset.custom),
                        );
                      }),
                      _colorRow("Secondary", settings.secondary, (c) {
                        _updateSettings(
                          settings.copyWith(secondary: c, preset: ThemePreset.custom),
                        );
                      }),
                      _colorRow("Surface", settings.surface, (c) {
                        _updateSettings(
                          settings.copyWith(surface: c, preset: ThemePreset.custom),
                        );
                      }),
                      _colorRow("Panels", settings.panel, (c) {
                        _updateSettings(
                          settings.copyWith(panel: c, preset: ThemePreset.custom),
                        );
                      }),
                      _colorRow("Text", settings.onSurface, (c) {
                        _updateSettings(
                          settings.copyWith(onSurface: c, preset: ThemePreset.custom),
                        );
                      }),
                      _colorRow("Muted text", settings.onSurfaceVariant, (c) {
                        _updateSettings(
                          settings.copyWith(onSurfaceVariant: c, preset: ThemePreset.custom),
                        );
                      }),
                      _colorRow("Outline", settings.outline, (c) {
                        _updateSettings(
                          settings.copyWith(outline: c, preset: ThemePreset.custom),
                        );
                      }),
                      if (settings.useGradient) ...[
                        _colorRow("Gradient start", settings.gradientStart, (c) {
                          _updateSettings(
                            settings.copyWith(gradientStart: c, preset: ThemePreset.custom),
                          );
                        }),
                        _colorRow("Gradient end", settings.gradientEnd, (c) {
                          _updateSettings(
                            settings.copyWith(gradientEnd: c, preset: ThemePreset.custom),
                          );
                        }),
                      ],
                      const SizedBox(height: 12),
                      Text("Font size", style: textTheme.titleMedium),
                      Slider(
                        value: settings.fontScale,
                        min: 0.9,
                        max: 1.3,
                        divisions: 8,
                        label: "${(settings.fontScale * 100).round()}%",
                        onChanged: (v) =>
                            _updateSettings(settings.copyWith(fontScale: v, preset: ThemePreset.custom)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionHeader(textTheme, "Accessibility"),
                _card(
                  context,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text("High contrast"),
                        subtitle: const Text("Increase contrast for text and borders."),
                        value: settings.highContrast,
                        onChanged: (val) => _updateSettings(
                          settings.copyWith(highContrast: val, preset: ThemePreset.custom),
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text("Reduce motion"),
                        subtitle: const Text("Limit animations and transitions."),
                        value: settings.reduceMotion,
                        onChanged: (val) => _updateSettings(
                          settings.copyWith(reduceMotion: val, preset: ThemePreset.custom),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _sectionHeader(textTheme, "AI usage"),
                _card(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Allow online AI access"),
                        subtitle:
                            const Text("Disable to keep AI features offline-only when possible."),
                        value: settings.aiOnlineAllowed,
                        onChanged: (val) => _updateSettings(
                          settings.copyWith(aiOnlineAllowed: val),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Daily AI token limit", style: textTheme.titleMedium),
                      Slider(
                        value: settings.aiDailyLimit.toDouble(),
                        min: 100,
                        max: 5000,
                        divisions: 49,
                        label: "${settings.aiDailyLimit} tokens",
                        onChanged: (v) =>
                            _updateSettings(settings.copyWith(aiDailyLimit: v.round())),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Current: ${settings.aiDailyLimit} tokens/day",
                          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_teachLoading)
                        const LinearProgressIndicator(minHeight: 4)
                      else
                        _aiConfigSection(textTheme, colors),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadTeachSettings() async {
    final s = await teachService.loadSettings();
    if (!mounted) return;
    setState(() {
      _teachSettings = s;
      _aiProvider = s.cloudProvider.isEmpty ? 'openai' : s.cloudProvider;
      _aiKeyCtrl.text = s.apiKey ?? '';
      _aiModelCtrl.text = s.cloudModel;
      _aiEndpointCtrl.text = s.cloudEndpoint;
      _teachLoading = false;
    });
  }

  Future<void> _saveTeachSettings() async {
    final current = (_teachSettings ?? TeachSettings())
      ..cloudProvider = _aiProvider
      ..apiKey = _aiKeyCtrl.text.trim()
      ..cloudModel = _aiModelCtrl.text.trim().isEmpty ? 'gpt-4o-mini' : _aiModelCtrl.text.trim()
      ..cloudEndpoint = _aiEndpointCtrl.text.trim();
    setState(() {
      _teachSettings = current;
    });
    await teachService.saveSettings(current);
  }

  Widget _aiConfigSection(TextTheme textTheme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text("AI provider", style: textTheme.titleMedium),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _aiProvider,
          items: const [
            DropdownMenuItem(value: 'openai', child: Text("OpenAI-compatible")),
            DropdownMenuItem(value: 'anthropic', child: Text("Anthropic")),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() => _aiProvider = val);
            _saveTeachSettings();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _aiKeyCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: "API key"),
          onChanged: (_) => _saveTeachSettings(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aiModelCtrl,
          decoration: const InputDecoration(labelText: "Model"),
          onChanged: (_) => _saveTeachSettings(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aiEndpointCtrl,
          decoration: const InputDecoration(labelText: "Custom endpoint (optional)"),
          onChanged: (_) => _saveTeachSettings(),
        ),
        const SizedBox(height: 8),
        Text(
          "These settings are used across AI features (Teach mode, future flashcard/quiz helpers).",
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(TextTheme textTheme, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: textTheme.titleMedium),
    );
  }

  Widget _colorRow(String label, Color color, ValueChanged<Color> onPicked) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: colors.outline),
        ),
      ),
      title: Text(label),
      subtitle: Text(_colorToHex(color)),
      trailing: TextButton(
        onPressed: () => _showColorPicker(label, color, onPicked),
        child: const Text("Change"),
      ),
    );
  }

  Future<void> _showColorPicker(
    String label,
    Color current,
    ValueChanged<Color> onPicked,
  ) async {
    Color temp = current;
    final controller = TextEditingController(text: _colorToHex(current));

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pick $label'),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _palette
                        .map(
                          (c) => GestureDetector(
                            onTap: () {
                              setModalState(() => temp = c);
                              controller.text = _colorToHex(c);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: temp == c ? Colors.white : Colors.black26,
                                  width: temp == c ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Hex color (e.g., #4B8BFE)',
                    ),
                    onChanged: (val) {
                      final parsed = _tryParseColor(val);
                      if (parsed != null) {
                        setModalState(() => temp = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: temp,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = _tryParseColor(controller.text);
                if (parsed != null) {
                  onPicked(parsed);
                } else {
                  onPicked(temp);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _applyPreset(ThemePreset preset, AppSettings current) {
    final base = AppSettings.fromPreset(preset).copyWith(
      fontScale: current.fontScale,
      highContrast: current.highContrast,
      reduceMotion: current.reduceMotion,
      aiDailyLimit: current.aiDailyLimit,
      aiOnlineAllowed: current.aiOnlineAllowed,
    );
    _updateSettings(base);
  }

  void _updateSettings(AppSettings settings) {
    appSettingsNotifier.value = settings;
    setState(() {});
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final path = await exportService.exportAll();
      if (!mounted) return;
      _showSnack(context, "Exported to $path");
    } catch (e) {
      _showSnack(context, "Export failed: $e");
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

Color? _tryParseColor(String input) {
  var value = input.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final intColor = int.tryParse(value, radix: 16);
  if (intColor == null) return null;
  return Color(intColor);
}

String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

const List<Color> _palette = [
  Color(0xFF4B8BFE),
  Color(0xFF7C3AED),
  Color(0xFFF97316),
  Color(0xFF22C55E),
  Color(0xFFE11D48),
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
  Color(0xFF14B8A6),
  Color(0xFF2563EB),
  Color(0xFF1E293B),
  Color(0xFFF8FAFC),
  Color(0xFF0F172A),
];

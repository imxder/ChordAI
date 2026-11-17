import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/chord_recognition_mode.dart';
import '../models/on_device_model.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/page_parts.dart';
import '../theme/ph.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: appState.serverUrl.replaceFirst(RegExp(r'^https?://'), ''),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    var value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Informe o endereço do servidor');
      return;
    }
    if (!value.startsWith('http')) value = 'http://$value';
    await appState.setServerUrl(value);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _selectMode(ChordRecognitionMode mode) async {
    await appState.setChordRecognitionMode(mode);
    setState(() => _error = null);
  }

  Future<void> _selectModel(OnDeviceModel model) async {
    await appState.setOnDeviceModel(model);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final mode = appState.chordRecognitionMode;
    final usesServer = mode == ChordRecognitionMode.server;
    return IosPage(
      title: 'Reconhecimento',
      trailing: usesServer
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _save,
              child: const Text(
                'Salvar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      children: [
        GroupedSection(
          top: 8,
          header: 'Reconhecimento de acordes',
          children: [
            for (final option in ChordRecognitionMode.values)
              CheckRow(
                title: option.label,
                subtitle: option.description,
                selected: mode == option,
                onTap: () => _selectMode(option),
              ),
          ],
        ),
        if (!usesServer)
          GroupedSection(
            header: 'Modelo no aparelho',
            footer:
                'O v3 + meu dataset mostra menos acorde quando não tem acorde '
                'sendo tocado (cordas abafadas, tarraxa, fala).',
            children: [
              for (final option in OnDeviceModel.values)
                CheckRow(
                  title: option.label,
                  subtitle: option.description,
                  selected: appState.onDeviceModel == option,
                  onTap: () => _selectModel(option),
                ),
            ],
          ),
        if (usesServer)
          GroupedSection(
            header: 'Endereço do servidor',
            footer:
                error ??
                'Só funciona com um computador na mesma rede Wi-Fi do celular '
                    'rodando o ChordAI-backend. Use o IP e a porta que aparecem no '
                    'terminal do servidor, 5000 (ou 5001 no Mac), ou o nome do '
                    'computador na rede (ex.: meu-mac.local:5001), que não muda '
                    'quando o IP muda.',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _save(),
                  style: const TextStyle(fontFamily: fontChord, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '192.168.0.10:5000',
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: error == null
                        ? null
                        : Icon(
                            Ph.warningCircleFill,
                            color: Theme.of(context).colorScheme.error,
                          ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

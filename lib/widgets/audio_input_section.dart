import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../state/app_state.dart';
import 'page_parts.dart';

/// Lista das entradas de áudio conectadas, com "Padrão do sistema" em
/// cima. Aparece em Configurações → Reconhecimento e no diálogo "Entrada de áudio"
/// do menu lateral (só no Windows e no Mac, ver canChooseAudioInput).
class AudioInputSection extends StatefulWidget {
  final double top;

  const AudioInputSection({super.key, this.top = 28});

  @override
  State<AudioInputSection> createState() => _AudioInputSectionState();
}

class _AudioInputSectionState extends State<AudioInputSection> {
  List<InputDevice> _devices = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final recorder = AudioRecorder();
    try {
      final devices = await recorder.listInputDevices();
      if (mounted) setState(() => _devices = devices);
    } catch (_) {
      // Sem a lista, fica só a entrada padrão do sistema.
    } finally {
      await recorder.dispose();
    }
  }

  Future<void> _select(String? id) async {
    await appState.setInputDeviceId(id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final savedId = appState.inputDeviceId;
    // Se a entrada salva foi desconectada, o app grava pela padrão (ver
    // chosenInputDevice), então é ela que aparece marcada.
    final connected = _devices.any((d) => d.id == savedId);
    return GroupedSection(
      top: widget.top,
      header: 'Entrada de áudio',
      footer: 'Vale pro afinador e pro reconhecimento.',
      children: [
        CheckRow(
          title: 'Padrão do sistema',
          selected: !connected,
          onTap: () => _select(null),
        ),
        for (final device in _devices)
          CheckRow(
            title: device.label.isEmpty ? device.id : device.label,
            selected: device.id == savedId,
            onTap: () => _select(device.id),
          ),
      ],
    );
  }
}

/// Diálogo do menu lateral do computador com a lista de entradas.
Future<void> showAudioInputDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AudioInputSection(top: 16),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Pronto'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

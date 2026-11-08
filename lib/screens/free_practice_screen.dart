import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../models/chord_prediction.dart';
import '../services/chord_recognizer.dart';
import '../services/chord_recognizer_factory.dart';
import '../services/on_device_chord_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import '../widgets/recognition_mode_badge.dart';
import '../theme/ph.dart';

class FreePracticeScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;

  const FreePracticeScreen({
    super.key,
    required this.serverUrl,
    this.inputDevice,
  });

  @override
  State<FreePracticeScreen> createState() => _FreePracticeScreenState();
}

class _FreePracticeScreenState extends State<FreePracticeScreen> {
  late final ChordRecognizer _service =
      createChordRecognizer(appState.chordRecognitionMode);

  bool _listening = false;
  String? _chord;
  double _confidence = 0.0;
  String _statusMessage = 'Toque em Ouvir e faça um acorde';

  @override
  void initState() {
    super.initState();
    if (widget.inputDevice != null) {
      _service.selectDevice(widget.inputDevice);
    }
  }

  Future<void> _toggle() async {
    if (_listening) {
      await _service.stop();
      setState(() {
        _listening = false;
        _statusMessage = 'Parado';
      });
      return;
    }

    final hasPermission = await _service.hasPermission();
    if (!hasPermission) {
      _showSnackBar('O app precisa de acesso ao microfone');
      return;
    }

    setState(() {
      _listening = true;
      _chord = null;
      _confidence = 0.0;
      _statusMessage = 'Ouvindo';
    });

    _service.start(
      serverUrl: widget.serverUrl,
      onPrediction: _handlePrediction,
      onError: (_) => _showSnackBar(
        chordRecognitionErrorMessage(appState.chordRecognitionMode),
      ),
    );
  }

  void _handlePrediction(ChordPrediction prediction) {
    if (!mounted) return;
    setState(() {
      switch (prediction.status) {
        case 'ok':
          _chord = prediction.chord;
          _confidence = prediction.confidence;
          _statusMessage = 'Ouvindo';
          break;
        case 'silence':
          _statusMessage = 'Ouvindo';
          break;
        case 'too_short':
          _statusMessage = 'Som muito curto, deixe o acorde soar';
          break;
        default:
          _statusMessage = prediction.message ?? 'Não reconheci o acorde';
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final chord = _chord;

    return IosPage(
      title: 'Reconhecer acorde',
      trailing: const RecognitionModeBadge(),
      bottomBar: BottomActionBar(
        child: FilledButton.icon(
          onPressed: _toggle,
          icon: Icon(_listening ? Ph.stopFill : Ph.microphoneFill, size: 20),
          label: Text(_listening ? 'Parar' : 'Ouvir'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: _listening ? colorScheme.onSurface : null,
            foregroundColor: _listening ? colorScheme.surface : null,
          ),
        ),
      ),
      children: [
        Material(
          color: context.tokens.cell,
          borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 110, child: GuitarNeck(chord: chord)),
                const SizedBox(width: 20),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    label: chord == null
                        ? 'Nenhum acorde reconhecido'
                        : 'Acorde $chord, ${chordFullName(chord)}',
                    excludeSemantics: true,
                    child: GlassEnter(
                      key: ValueKey(chord),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              chord ?? '–',
                              style: textTheme.displayLarge?.copyWith(
                                color: chord == null
                                    ? colorScheme.outlineVariant
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            chord != null
                                ? chordFullName(chord)
                                : 'Nenhum acorde ainda',
                            style: textTheme.bodyLarge,
                          ),
                          if (_confidence > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${(_confidence * 100).toStringAsFixed(0)}% de confiança',
                              style: textTheme.bodySmall?.copyWith(
                                fontFamily: fontChord,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: StatusLine(
            icon: _listening ? Ph.waveform : null,
            text: _statusMessage,
            color: _listening ? colorScheme.primary : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            'O app mostra o último acorde que reconheceu.',
            style: textTheme.bodySmall,
          ),
        ),
        if (_service case final OnDeviceChordService service)
          if (service.lastInferenceMicros != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                'Inferência: ${(service.lastInferenceMicros! / 1000).toStringAsFixed(1)} ms',
                style: textTheme.bodySmall,
              ),
            ),
      ],
    );
  }
}

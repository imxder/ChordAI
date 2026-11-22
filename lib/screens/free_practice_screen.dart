import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/chord_names.dart';
import '../models/chord_prediction.dart';
import '../services/audio_input.dart';
import '../services/chord_recognizer.dart';
import '../services/chord_recognizer_factory.dart';
import '../services/on_device_chord_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/mic_lifecycle.dart';
import '../widgets/guitar_neck.dart';
import '../widgets/page_parts.dart';
import '../widgets/recognition_mode_badge.dart';
import '../theme/ph.dart';
import '../theme/platform_style.dart';
import '../widgets/desktop_input.dart';

class FreePracticeScreen extends StatefulWidget {
  final String serverUrl;
  final InputDevice? inputDevice;

  /// Só pros testes: um reconhecedor falso no lugar do microfone.
  final ChordRecognizer? recognizer;

  const FreePracticeScreen({
    super.key,
    required this.serverUrl,
    this.inputDevice,
    this.recognizer,
  });

  @override
  State<FreePracticeScreen> createState() => _FreePracticeScreenState();
}

class _FreePracticeScreenState extends State<FreePracticeScreen>
    with MicLifecycle {
  late final ChordRecognizer _service =
      widget.recognizer ?? createChordRecognizer(appState.chordRecognitionMode);

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

  // Escondendo o app, para de ouvir como se a pessoa tivesse apertado Parar.
  @override
  void onAppHidden() {
    if (_listening) _toggle();
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
      onError: (error) {
        // Microfone bloqueado ou entrada desconectada (só no computador): o
        // serviço já parou de ouvir, então a tela volta pro Ouvir.
        if (error is MicrophoneProblem) {
          if (mounted) {
            setState(() {
              _listening = false;
              _statusMessage = 'Parado';
            });
          }
          _showSnackBar(error.message);
          return;
        }
        _showSnackBar(
          chordRecognitionErrorMessage(appState.chordRecognitionMode),
        );
      },
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
    // No computador é a tela que eu mostro na apresentação: braço e nome do
    // acorde bem maiores, pra ver de longe.
    final big = isDesktop;
    final chordStyle = textTheme.displayLarge?.copyWith(
      fontSize: big ? 120 : null,
      color: chord == null ? colorScheme.outlineVariant : null,
    );

    return SpaceToToggle(
      onToggle: _toggle,
      child: IosPage(
        title: 'Reconhecer acorde',
        bottomBar: BottomActionBar(
          child: FilledButton.icon(
            onPressed: _toggle,
            icon: Icon(_listening ? Ph.stopFill : Ph.microphoneFill, size: 20),
            label: Text(_listening ? 'Parar' : 'Ouvir'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: _listening ? stopButtonColor(context) : null,
              foregroundColor: _listening ? onStopButtonColor(context) : null,
            ),
          ),
        ),
        children: [
          Material(
            color: context.tokens.cell,
            borderRadius: BorderRadius.circular(GlassTokens.radiusXl),
            child: Padding(
              padding: EdgeInsets.all(big ? 40 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: big ? 220 : 110,
                    child: GuitarNeck(chord: chord),
                  ),
                  SizedBox(width: big ? 40 : 20),
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
                              child: Text(chord ?? '–', style: chordStyle),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: RecognitionModeBadge(),
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
      ),
    );
  }
}

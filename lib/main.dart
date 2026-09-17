import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'models/app_theme.dart';
import 'models/chord_prediction.dart';
import 'screens/achievements_screen.dart';
import 'screens/chord_list_screen.dart';
import 'screens/lyric_sheet_list_screen.dart';
import 'screens/practice_session_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tuner_screen.dart';
import 'services/chord_recognition_service.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appState.loadProgress();
  runApp(const ChordAIApp());
}

class ChordAIApp extends StatelessWidget {
  const ChordAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final seedColor =
            appThemeOptions[appState.selectedThemeIndex].color;
        return MaterialApp(
          title: 'ChordAI',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
            useMaterial3: true,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = ChordRecognitionService();

  bool _listening = false;
  String _chord = '—';
  double _confidence = 0.0;
  String _statusMessage = 'Toque em Iniciar';

  List<InputDevice> _inputDevices = [];
  InputDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _loadInputDevices();
  }

  Future<void> _loadInputDevices() async {
    try {
      final devices = await _service.listInputDevices();
      if (!mounted) return;
      setState(() {
        _inputDevices = devices;
      });
    } catch (_) {}
  }

  Future<void> _toggleListening() async {
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
      _showSnackBar('Permissão de microfone negada');
      return;
    }

    setState(() {
      _listening = true;
      _statusMessage = 'Ouvindo...';
    });

    _service.start(
      serverUrl: appState.serverUrl,
      onPrediction: _handlePrediction,
      onError: _handleError,
    );
  }

  void _handlePrediction(ChordPrediction prediction) {
    if (!mounted) return;
    setState(() {
      switch (prediction.status) {
        case 'ok':
          _chord = prediction.chord ?? '?';
          _confidence = prediction.confidence;
          _statusMessage = 'Ouvindo...';
          break;
        case 'silence':
          _statusMessage = 'Silêncio...';
          break;
        case 'too_short':
          _statusMessage = 'Áudio muito curto, continue tocando...';
          break;
        default:
          _statusMessage =
              prediction.message ?? 'Acorde não identificado';
      }
    });
  }

  void _handleError(Object error) {
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Erro ao conectar com o servidor';
    });
  }

  void _openPracticeSession() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PracticeSessionScreen(
          serverUrl: appState.serverUrl,
          inputDevice: _selectedDevice,
        ),
      ),
    );
  }

  void _openChordList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChordListScreen(
          serverUrl: appState.serverUrl,
          inputDevice: _selectedDevice,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChordAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Progresso',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (_inputDevices.isNotEmpty)
                DropdownButtonFormField<InputDevice?>(
                  initialValue: _selectedDevice,
                  decoration: const InputDecoration(
                    labelText: 'Fonte de áudio',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<InputDevice?>(
                      value: null,
                      child: Text('Padrão do sistema'),
                    ),
                    ..._inputDevices.map(
                      (d) => DropdownMenuItem<InputDevice?>(
                        value: d,
                        child: Text(d.label, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: _listening
                      ? null
                      : (device) {
                          setState(() => _selectedDevice = device);
                          _service.selectDevice(device);
                        },
                ),
              const Spacer(),
              Text(
                _chord,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (_confidence > 0)
                Text('${(_confidence * 100).toStringAsFixed(0)}% de confiança'),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _toggleListening,
                icon: Icon(_listening ? Icons.stop : Icons.mic),
                label: Text(_listening ? 'Parar' : 'Iniciar'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _listening ? Colors.red : null,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _listening ? null : _openPracticeSession,
                icon: const Icon(Icons.library_music),
                label: const Text('Praticar com partitura'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _listening ? null : _openChordList,
                icon: const Icon(Icons.grid_view),
                label: const Text('Aprender acordes'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _listening
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LyricSheetListScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.lyrics_outlined),
                label: const Text('Letra e cifra'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _listening
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TunerScreen()),
                        );
                      },
                icon: const Icon(Icons.tune),
                label: const Text('Afinador'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

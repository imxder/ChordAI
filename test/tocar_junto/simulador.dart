import 'dart:async';
import 'dart:math';

import 'package:chordai/models/chord_prediction.dart';
import 'package:chordai/models/score.dart';
import 'package:chordai/services/chord_recognizer.dart';
import 'package:chordai/services/chord_stabilizer.dart';
import 'package:record/record.dart';

class Tocado {
  final String? acorde;
  final int inicioMs;
  final int fimMs;

  const Tocado(this.acorde, this.inicioMs, this.fimMs);
}

class ModeloFalso {
  final Set<String> conhecidos;
  final double taxaDeErro;
  final Set<String> naoOuve;
  final Random _rng;

  ModeloFalso({
    required this.conhecidos,
    this.taxaDeErro = 0,
    this.naoOuve = const {},
    int semente = 42,
  }) : _rng = Random(semente);

  ChordPrediction ler(List<Tocado> tocados, int fimMs, {int janelaMs = 1500}) {
    final inicio = fimMs - janelaMs;
    final tempo = <String, int>{};
    var tocando = 0;
    for (final t in tocados) {
      final int sobreposto = min(fimMs, t.fimMs) - max(inicio, t.inicioMs);
      if (sobreposto <= 0 || t.acorde == null) continue;
      tempo[t.acorde!] = (tempo[t.acorde!] ?? 0) + sobreposto;
      tocando += sobreposto;
    }
    if (tocando < janelaMs * 0.2) {
      return const ChordPrediction(status: 'silence');
    }
    String? maior;
    var maiorTempo = 0;
    tempo.forEach((acorde, ms) {
      if (ms > maiorTempo) {
        maiorTempo = ms;
        maior = acorde;
      }
    });
    if (maior == null || maiorTempo < janelaMs * 0.5) {
      return const ChordPrediction(status: 'unknown', confidence: 0.3);
    }
    if (!conhecidos.contains(maior) || naoOuve.contains(maior)) {
      return const ChordPrediction(status: 'unknown', confidence: 0.3);
    }
    if (_rng.nextDouble() < taxaDeErro) {
      if (_rng.nextBool()) {
        return const ChordPrediction(status: 'unknown', confidence: 0.3);
      }
      final outros = conhecidos.where((c) => c != maior).toList();
      return ChordPrediction(
        status: 'ok',
        chord: outros[_rng.nextInt(outros.length)],
        confidence: 0.6,
      );
    }
    return ChordPrediction(status: 'ok', chord: maior, confidence: 0.9);
  }
}

class Leitura {
  final int ms;
  final ChordPrediction previsao;

  const Leitura(this.ms, this.previsao);
}

class ReconhecedorFalso implements ChordRecognizer {
  final ModeloFalso modelo;
  final List<Tocado> tocados;
  final DateTime Function() agora;
  final bool estabilizar;

  final List<Leitura> cruas = [];
  final List<Leitura> repassadas = [];
  Timer? _timer;
  DateTime? _inicio;
  bool _rodando = false;

  ReconhecedorFalso({
    required this.modelo,
    required this.tocados,
    required this.agora,
    this.estabilizar = false,
  });

  int get _ms => agora().difference(_inicio!).inMilliseconds;

  @override
  bool get isRunning => _rodando;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<List<InputDevice>> listInputDevices() async => const [];

  @override
  void selectDevice(InputDevice? device) {}

  @override
  Future<void> start({
    required void Function(ChordPrediction prediction) onPrediction,
    required void Function(Object error) onError,
  }) async {
    _inicio = agora();
    _rodando = true;
    cruas.clear();
    repassadas.clear();
    final estabilizador = ChordStabilizer(clock: agora);
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final ms = _ms;
      final leitura = ms < 1500
          ? const ChordPrediction(status: 'too_short')
          : modelo.ler(tocados, ms);
      cruas.add(Leitura(ms, leitura));
      final saida = estabilizar ? estabilizador.process(leitura) : leitura;
      if (saida != null) {
        repassadas.add(Leitura(ms, saida));
        onPrediction(saida);
      }
    });
  }

  @override
  Future<void> stop() async {
    _rodando = false;
    _timer?.cancel();
  }

  @override
  Future<void> dispose() => stop();
}

List<Tocado> tocarPelaCifra(
  List<ChordStep> passos, {
  required int bpm,
  int contagem = 4,
  int atrasoMs = 0,
  Map<int, String?> trocas = const {},
}) {
  final tempoMs = 60000 / bpm;
  var inicio = contagem * tempoMs + atrasoMs;
  final out = <Tocado>[];
  for (var i = 0; i < passos.length; i++) {
    final fim = inicio + passos[i].beats * tempoMs;
    out.add(
      Tocado(
        trocas.containsKey(i) ? trocas[i] : passos[i].chord,
        inicio.round(),
        fim.round(),
      ),
    );
    inicio = fim;
  }
  return out;
}

List<Tocado> tocarNoTempo(
  List<String?> acordes, {
  required int msPorAcorde,
  int atrasoMs = 0,
  Map<int, String?> trocas = const {},
}) {
  return [
    for (var i = 0; i < acordes.length; i++)
      Tocado(
        trocas.containsKey(i) ? trocas[i] : acordes[i],
        i * msPorAcorde + atrasoMs,
        (i + 1) * msPorAcorde + atrasoMs,
      ),
  ];
}

import 'tuner_note.dart';

class TuningPreset {
  final String id;
  final String name;
  final List<String> notes;

  const TuningPreset({required this.id, required this.name, required this.notes});

  List<TunerNote> get strings => buildTuning(notes);
}

const List<TuningPreset> tuningPresets = [
  TuningPreset(
    id: 'padrao',
    name: 'Padrão (E A D G B E)',
    notes: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'],
  ),
  TuningPreset(
    id: 'drop_d',
    name: 'Drop D (D A D G B E)',
    notes: ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'],
  ),
  TuningPreset(
    id: 'meio_tom_abaixo',
    name: 'Meio tom abaixo',
    notes: ['D#2', 'G#2', 'C#3', 'F#3', 'A#3', 'D#4'],
  ),
  TuningPreset(
    id: 'open_g',
    name: 'Open G (D G D G B D)',
    notes: ['D2', 'G2', 'D3', 'G3', 'B3', 'D4'],
  ),
  TuningPreset(
    id: 'open_d',
    name: 'Open D (D A D F# A D)',
    notes: ['D2', 'A2', 'D3', 'F#3', 'A3', 'D4'],
  ),
  TuningPreset(
    id: 'dadgad',
    name: 'DADGAD',
    notes: ['D2', 'A2', 'D3', 'G3', 'A3', 'D4'],
  ),
];

const String customTuningId = 'custom';

const List<String> availableTuningNotes = [
  'C2', 'C#2', 'D2', 'D#2', 'E2', 'F2', 'F#2', 'G2', 'G#2', 'A2', 'A#2', 'B2',
  'C3', 'C#3', 'D3', 'D#3', 'E3', 'F3', 'F#3', 'G3', 'G#3', 'A3', 'A#3', 'B3',
  'C4', 'C#4', 'D4', 'D#4', 'E4',
];

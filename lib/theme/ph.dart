import 'package:flutter/widgets.dart';

// Fontes do @phosphor-icons/web 2.1.2 (MIT). O phosphor_flutter não compila mais:
// estende IconData, que virou classe final.
abstract final class Ph {
  static const _regular = 'PhosphorRegular';
  static const _fill = 'PhosphorFill';
  static const _duotone = 'PhosphorDuotone';

  static const house = IconData(0xe2c2, fontFamily: _regular);
  static const musicNotes = IconData(0xe340, fontFamily: _regular);
  static const squaresFour = IconData(0xe464, fontFamily: _regular);
  static const userCircle = IconData(0xe4c4, fontFamily: _regular);
  static const check = IconData(0xe182, fontFamily: _regular);
  static const x = IconData(0xe4f6, fontFamily: _regular);
  static const caretRight = IconData(0xe13a, fontFamily: _regular);
  static const plus = IconData(0xe3d4, fontFamily: _regular);
  static const minus = IconData(0xe32a, fontFamily: _regular);
  static const arrowUp = IconData(0xe08e, fontFamily: _regular);
  static const arrowDown = IconData(0xe03e, fontFamily: _regular);
  static const textAa = IconData(0xe6ee, fontFamily: _regular);
  static const waveform = IconData(0xe802, fontFamily: _regular);
  static const gauge = IconData(0xe628, fontFamily: _regular);

  static const houseFill = IconData(0xe2c2, fontFamily: _fill);
  static const musicNotesFill = IconData(0xe340, fontFamily: _fill);
  static const squaresFourFill = IconData(0xe464, fontFamily: _fill);
  static const userCircleFill = IconData(0xe4c4, fontFamily: _fill);
  static const userFill = IconData(0xe4c2, fontFamily: _fill);
  static const checkCircleFill = IconData(0xe184, fontFamily: _fill);
  static const microphoneFill = IconData(0xe326, fontFamily: _fill);
  static const playFill = IconData(0xe3d0, fontFamily: _fill);
  static const stopFill = IconData(0xe46c, fontFamily: _fill);
  static const bookOpenFill = IconData(0xe0e6, fontFamily: _fill);
  static const backpackFill = IconData(0xe922, fontFamily: _fill);
  static const wrenchFill = IconData(0xe5d4, fontFamily: _fill);
  static const gaugeFill = IconData(0xe628, fontFamily: _fill);
  static const arrowsClockwiseFill = IconData(0xe094, fontFamily: _fill);
  static const bandaidsFill = IconData(0xe0b2, fontFamily: _fill);
  static const circleHalfFill = IconData(0xe18c, fontFamily: _fill);
  static const paletteFill = IconData(0xe6c8, fontFamily: _fill);
  static const desktopFill = IconData(0xe560, fontFamily: _fill);
  static const metronomeFill = IconData(0xec8e, fontFamily: _fill);
  static const lightbulbFill = IconData(0xe2dc, fontFamily: _fill);
  static const warningCircleFill = IconData(0xe4e2, fontFamily: _fill);

  static const guitarDuotone = PhDuotone(
    IconData(0xea8a, fontFamily: _duotone),
    IconData(0xea8b, fontFamily: _duotone),
  );
  static const musicNotesDuotone = PhDuotone(
    IconData(0xe340, fontFamily: _duotone),
    IconData(0xe341, fontFamily: _duotone),
  );
  static const gaugeDuotone = PhDuotone(
    IconData(0xe628, fontFamily: _duotone),
    IconData(0xe629, fontFamily: _duotone),
  );
  static const earDuotone = PhDuotone(
    IconData(0xe70c, fontFamily: _duotone),
    IconData(0xe70d, fontFamily: _duotone),
  );
}

class PhDuotone {
  final IconData back;
  final IconData front;

  const PhDuotone(this.back, this.front);
}

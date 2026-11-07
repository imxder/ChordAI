import 'package:flutter/material.dart';

class AppThemeOption {
  final String name;
  final Color color;
  // No fundo escuro a cor original some; essa versão mais clara mantém o contraste.
  final Color darkColor;

  const AppThemeOption({
    required this.name,
    required this.color,
    required this.darkColor,
  });
}

const List<AppThemeOption> appThemeOptions = [
  AppThemeOption(
    name: 'Terracota',
    color: Color(0xFFA8461F),
    darkColor: Color(0xFFE8895F),
  ),
  AppThemeOption(
    name: 'Oliva',
    color: Color(0xFF55643A),
    darkColor: Color(0xFFAABB84),
  ),
  AppThemeOption(
    name: 'Vinho',
    color: Color(0xFF8C3B4A),
    darkColor: Color(0xFFE6919F),
  ),
];

enum AppAppearance {
  paper('Papel', 'Fundo bege claro'),
  white('Branco', 'Fundo branco'),
  dark('Escuro', 'Fundo escuro, bom pra tocar à noite'),
  system('Igual ao celular', 'Papel ou escuro, conforme o sistema');

  final String label;
  final String description;

  const AppAppearance(this.label, this.description);
}

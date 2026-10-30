import 'package:flutter/material.dart';

class AppThemeOption {
  final String name;
  final Color color;
  final int cost;

  const AppThemeOption({
    required this.name,
    required this.color,
    required this.cost,
  });
}

const List<AppThemeOption> appThemeOptions = [
  AppThemeOption(name: 'Terracota', color: Color(0xFFC1623D), cost: 0),
  AppThemeOption(name: 'Oliva', color: Color(0xFF6B7A4F), cost: 50),
  AppThemeOption(name: 'Vinho', color: Color(0xFF8C3B4A), cost: 100),
];

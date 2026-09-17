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
  AppThemeOption(name: 'Roxo', color: Colors.deepPurple, cost: 0),
  AppThemeOption(name: 'Verde', color: Colors.teal, cost: 50),
  AppThemeOption(name: 'Laranja', color: Colors.deepOrange, cost: 100),
];

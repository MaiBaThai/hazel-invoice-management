import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final String nameVi;
  final Color seedColor;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.nameVi,
    required this.seedColor,
  });
}

const List<ThemePreset> themePresets = [
  ThemePreset(
    id: 'rose',
    name: 'Rose',
    nameVi: 'Hồng phấn',
    seedColor: Colors.pink,
  ),
  ThemePreset(
    id: 'lavender',
    name: 'Lavender',
    nameVi: 'Tím oải hương',
    seedColor: Colors.deepPurple,
  ),
  ThemePreset(
    id: 'mint',
    name: 'Mint',
    nameVi: 'Xanh bạc hà',
    seedColor: Colors.teal,
  ),
  ThemePreset(
    id: 'coral',
    name: 'Coral',
    nameVi: 'Cam san hô',
    seedColor: Colors.orange,
  ),
  ThemePreset(
    id: 'gold',
    name: 'Gold',
    nameVi: 'Vàng hoàng gia',
    seedColor: Colors.amber,
  ),
  ThemePreset(
    id: 'ocean',
    name: 'Ocean',
    nameVi: 'Xanh đại dương',
    seedColor: Colors.blue,
  ),
];

ThemeData getThemeData(String presetId) {
  final preset = themePresets.firstWhere(
    (p) => p.id == presetId,
    orElse: () => themePresets.first, // fallback to rose
  );

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: preset.seedColor,
      primary: preset.seedColor,
    ),
    useMaterial3: true,
  );
}

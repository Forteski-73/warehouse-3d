import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'screens/warehouse_screen.dart';

void main() {
  runApp(const WmsApp());
}

class WmsApp extends StatefulWidget {
  const WmsApp({super.key});

  @override
  State<WmsApp> createState() => _WmsAppState();
}

class _WmsAppState extends State<WmsApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WMS 3D',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: WarehouseScreen(themeMode: _themeMode, onToggleTheme: _toggleTheme),
    );
  }
}

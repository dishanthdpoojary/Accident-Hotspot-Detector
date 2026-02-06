// lib/main.dart
import 'package:flutter/material.dart';
import 'map_screen.dart';

void main() {
  runApp(const AccidentHotspotApp());
}

class AccidentHotspotApp extends StatelessWidget {
  const AccidentHotspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accident Hotspot App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: const MapScreen(),
    );
  }
}

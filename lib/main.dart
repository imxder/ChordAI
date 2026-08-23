import 'package:flutter/material.dart';

void main() {
  runApp(const ChordAIApp());
}

class ChordAIApp extends StatelessWidget {
  const ChordAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChordAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChordAI')),
      body: const Center(child: Text('Reconhecimento de acordes em breve')),
    );
  }
}

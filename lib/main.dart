import 'package:desafio_tecnico_spark/viewmodels/VideoViewModel.dart';
import 'package:desafio_tecnico_spark/views/HomeView.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Clone',
      theme: ThemeData.dark(),
      home: const HomeView(),
    );
  }
}

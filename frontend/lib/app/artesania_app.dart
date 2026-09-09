import 'package:flutter/material.dart';
import 'features/home/pages/current_home_page.dart';

class ArtesaniaApp extends StatelessWidget {
  const ArtesaniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artesãs de Heliópolis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F0E3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF238F89),
          brightness: Brightness.light,
        ),
        fontFamily: 'Nunito',
      ),
      home: const CurrentHomePage(),
    );
  }
}

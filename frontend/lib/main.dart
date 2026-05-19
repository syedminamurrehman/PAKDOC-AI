import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'models/models.dart';
import 'package:pak_doc_ai/screens/home_screen.dart';

void main() {
  runApp(const PakDocAI());
}

class PakDocAI extends StatelessWidget {
  const PakDocAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PakDocAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFBFBFD),
        primaryColor: const Color(0xFF004AAD),
        textTheme: GoogleFonts.interTextTheme().apply(
          bodyColor: const Color(0xFF1D1D1F),
          displayColor: const Color(0xFF1D1D1F),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF004AAD),
          primary: const Color(0xFF004AAD),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

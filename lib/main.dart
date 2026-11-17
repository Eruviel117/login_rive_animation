import 'package:flutter/material.dart';
// Importar Firebase y las credenciales del proyecto
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';

// main ahora es asíncrono porque espera a que Firebase se conecte
Future<void> main() async {
  // Encender el puente nativo antes de usar Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase usando las credenciales de firebase_options.dart
  await Firebase.initializeApp(options: firebaseOptions);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen()
    );
  }
}

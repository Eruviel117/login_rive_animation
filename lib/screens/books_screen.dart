import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
//9.4 Importar Firebase Auth y el Login para cerrar sesión
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  // 6.1 Parámetro clave: URL base de la API library-backend (puerto 8091)
  // - Web (Chrome): http://localhost:8091
  // - Emulador Android: http://10.0.2.2:8091 (10.0.2.2 apunta a la PC desde el emulador)
  // - Celular físico: usar la IP de tu computadora (ej. http://192.168.1.X:8091)
  // 10.2 URL indicada al correr la app (celular físico), por ejemplo:
  //      flutter run --dart-define=API_URL=http://localhost:8091  (con adb reverse)
  static const String _apiUrl = String.fromEnvironment('API_URL');

  // 10.1 Si no se indicó API_URL, se elige automáticamente según la plataforma
  static String get baseUrl {
    if (_apiUrl.isNotEmpty) return _apiUrl;
    return (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? 'http://10.0.2.2:8091'
        : 'http://localhost:8091';
  }

  // 6.2 Función para pedir la lista de libros al endpoint GET /books
  Future<List<dynamic>> fetchBooks() async {
    final response = await http.get(Uri.parse('$baseUrl/books'));

    if (response.statusCode == 200) {
      // utf8.decode para que se vean bien los acentos (ñ, á, é...)
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error al cargar libros de la API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de libros'),
        actions: [
          //9.5 Cerrar sesión en Firebase y regresar al Login
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      // 6.3 FutureBuilder: espera la respuesta de la API y dibuja el resultado
      body: FutureBuilder<List<dynamic>>(
        future: fetchBooks(),
        builder: (context, snapshot) {
          // Mientras responde el servidor, mostrar indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hubo un error de conexión
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final books = snapshot.data ?? [];

          // 6.4 Mostrar los libros de la base de datos con su categoría
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: const Icon(Icons.menu_book),
                title: Text(book['title'].toString()),
                subtitle: Text(
                  '${book['author']} · ${book['category']?['name'] ?? 'Sin categoría'}',
                ),
                trailing: Text('Disponibles: ${book['availableQuantity']}'),
              );
            },
          );
        },
      ),
    );
  }
}

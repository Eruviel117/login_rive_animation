import 'package:flutter/material.dart';

// Pantalla temporal: en el siguiente paso aquí se pedirán los productos a Spring Boot
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos de Spring Boot')),
      body: const Center(child: Text('Productos')),
    );
  }
}

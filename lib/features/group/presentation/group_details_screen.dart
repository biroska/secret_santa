import 'package:flutter/material.dart';

class GroupDetailsScreen extends StatelessWidget {
  const GroupDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Grupo'),
      ),
      body: const Center(
        child: Text('Tela de detalhes do grupo.'),
      ),
    );
  }
}
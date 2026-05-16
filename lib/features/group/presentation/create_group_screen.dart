import 'package:flutter/material.dart';

class CreateGroupScreen extends StatelessWidget {
  const CreateGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Grupo'),
      ),
      body: const Center(
        child: Text('Tela para criar um novo grupo de amigo secreto.'),
      ),
    );
  }
}
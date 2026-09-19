import 'package:flutter/material.dart';

/// Chave global do ScaffoldMessenger, permitindo exibir SnackBars mesmo depois
/// de já ter navegado para outra rota (ex.: notificar "evento não encontrado"
/// logo após redirecionar para a Home a partir de um deep link).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

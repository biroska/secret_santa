import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart'; // Para context.pop()

import '../../../dtos/new_event_dto.dart'; // Importando o NewEventDto
import '../../../services/firestore/event_service.dart'; // Importando o EventService

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({
    super.key,
    required this.eventService,
  }); // Adicionando eventService

  final EventService eventService; // Declarando eventService

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _drawDateController = TextEditingController();
  DateTime? _selectedEventDate;
  DateTime? _selectedDrawDate;
  bool _isSaving = false; // Estado para controlar o carregamento

  Future<void> _selectDate(
    BuildContext context, {
    required bool isDrawDate,
  }) async {
    final currentDate = isDrawDate
        ? _selectedDrawDate ?? DateTime.now()
        : _selectedEventDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isDrawDate) {
          _selectedDrawDate = picked;
          _drawDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _selectedEventDate = picked;
          _eventDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      try {
        final newEventDto = NewEventDto(
          title: _titleController.text,
          description: _descriptionController.text,
          eventDate: _selectedEventDate!,
          drawDate: _selectedDrawDate!,
        );

        await widget.eventService.createEvent(newEventDto);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento criado com sucesso!')),
        );
        context.pop(
          true,
        ); // Volta para a tela anterior (HomeScreen) e indica sucesso
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar evento: $e')));
        context.pop(false); // Volta para a tela anterior e indica falha
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _eventDateController.dispose();
    _drawDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Evento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventDateController,
                decoration: const InputDecoration(
                  labelText: 'Data Evento',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, isDrawDate: false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione a data do evento';
                  }
                  if (_selectedEventDate == null) {
                    return 'Data do evento inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _drawDateController,
                decoration: const InputDecoration(
                  labelText: 'Data do Sorteio',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.card_giftcard),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, isDrawDate: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione a data do sorteio';
                  }
                  if (_selectedDrawDate == null) {
                    return 'Data do sorteio inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : _submitForm, // Desabilita o botão durante o salvamento
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Salvar Evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

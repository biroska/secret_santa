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

  // Gift value fields
  bool _defineGiftValue = false;
  double _giftValue = 0;
  int _sliderMax = 300;
  late final TextEditingController _sliderMaxController;

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedEventDate != null &&
        _selectedDrawDate != null &&
        _isDateOnOrAfterToday(_selectedEventDate!) &&
        _isDateOnOrAfterToday(_selectedDrawDate!) &&
        !_selectedEventDate!.isBefore(_selectedDrawDate!);
  }

  bool _isDateOnOrAfterToday(DateTime date) {
    final today = DateTime.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return !normalizedDate.isBefore(normalizedToday);
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isDrawDate,
  }) async {
    final today = DateTime.now();
    final currentDate = isDrawDate
        ? _selectedDrawDate ?? today
        : _selectedEventDate ?? (_selectedDrawDate ?? today);
    final firstDate = isDrawDate
        ? DateTime(today.year, today.month, today.day)
        : (_selectedDrawDate != null
            ? DateTime(
                _selectedDrawDate!.year,
                _selectedDrawDate!.month,
                _selectedDrawDate!.day,
              )
            : DateTime(today.year, today.month, today.day));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: firstDate,
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
            maxGiftValue: _defineGiftValue ? _giftValue.round() : null,
          );

          await widget.eventService.createEvent(newEventDto);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evento criado com sucesso!')),
          );
          context.pop(true); // Volta para a tela anterior (HomeScreen) e indica sucesso
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
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
    _eventDateController.addListener(() => setState(() {}));
    _drawDateController.addListener(() {
      // Se a data do sorteio for apagada, limpar e bloquear a data do evento
      if (_drawDateController.text.isEmpty) {
        _selectedDrawDate = null;
        _selectedEventDate = null;
        _eventDateController.text = '';
      }
      setState(() {});
    });

    // Slider max controller
    _sliderMaxController = TextEditingController(text: _sliderMax.toString());
    _sliderMaxController.addListener(() {
      final parsed = int.tryParse(_sliderMaxController.text);
      if (parsed != null) {
        // Enforce minimum 50 and multiples of 10
        int normalized = parsed;
        if (normalized < 50) normalized = 50;
        // Round to nearest multiple of 10
        normalized = ((normalized + 5) ~/ 10) * 10;
        if (normalized != parsed) {
          // Atualiza o texto apenas se necessário
          _sliderMaxController.text = normalized.toString();
          _sliderMaxController.selection = TextSelection.fromPosition(
              TextPosition(offset: _sliderMaxController.text.length));
        }
        setState(() {
          _sliderMax = normalized;
          // Ajusta giftValue para respeitar o novo máximo e ser múltiplo de 10
          if (_giftValue > _sliderMax) _giftValue = _sliderMax.toDouble();
          _giftValue = ((_giftValue / 10).round() * 10).clamp(0, _sliderMax).toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _eventDateController.dispose();
    _drawDateController.dispose();
    _sliderMaxController.dispose();
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
                  if (!_isDateOnOrAfterToday(_selectedDrawDate!)) {
                    return 'A data do sorteio deve ser maior ou igual a hoje';
                  }
                  if (_selectedEventDate != null &&
                      _selectedDrawDate!.isAfter(_selectedEventDate!)) {
                    return 'A data do sorteio deve ser menor ou igual à data do evento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventDateController,
                decoration: const InputDecoration(
                  labelText: 'Data do Evento',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                enabled: _selectedDrawDate != null,
                readOnly: true,
                onTap: () => _selectDate(context, isDrawDate: false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione a data do evento';
                  }
                  if (_selectedEventDate == null) {
                    return 'Data do evento inválida';
                  }
                  if (!_isDateOnOrAfterToday(_selectedEventDate!)) {
                    return 'A data do evento deve ser maior ou igual a hoje';
                  }
                  if (_selectedDrawDate != null &&
                      _selectedEventDate!.isBefore(_selectedDrawDate!)) {
                    return 'A data do evento deve ser maior ou igual à data do sorteio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Definir valor dos presentes'),
                value: _defineGiftValue,
                onChanged: (v) => setState(() => _defineGiftValue = v),
              ),
              if (_defineGiftValue)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _giftValue,
                          min: 0,
                          max: _sliderMax.toDouble(),
                          divisions: _sliderMax > 0 ? (_sliderMax ~/ 10) : null,
                          label: _giftValue.round().toString(),
                          onChanged: (val) => setState(() {
                            // Forçar passos de 10 e múltiplos de 10
                            final rounded = ((val / 10).round() * 10).toDouble();
                            _giftValue = rounded.clamp(0, _sliderMax).toDouble();
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          controller: _sliderMaxController,
                          decoration: const InputDecoration(
                            labelText: 'Máx.',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving || !_isFormValid ? null : _submitForm,
                style: _isFormValid
                    ? null
                    : ElevatedButton.styleFrom(backgroundColor: Colors.grey),
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

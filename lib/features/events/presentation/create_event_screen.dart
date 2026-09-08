import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../dtos/new_event_dto.dart';
import '../../../services/firestore/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({
    super.key,
    required this.eventService,
  });

  final EventService eventService;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  DateTime? _selectedEventDate;
  bool _isSaving = false;

  bool _defineGiftValue = false;
  double _giftValue = 0;
  int _sliderMax = 300;
  late final TextEditingController _sliderMaxController;

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _selectedEventDate != null &&
        _isDateOnOrAfterToday(_selectedEventDate!);
  }

  bool _isDateOnOrAfterToday(DateTime date) {
    final today = DateTime.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return !normalizedDate.isBefore(normalizedToday);
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InputDecoration(
      labelText: label,
      hintText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      prefixIcon: icon == null ? null : Icon(icon, size: 20, color: Colors.grey[600]),
      suffixIcon: icon == null ? null : Icon(icon, size: 20, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime.now();
    final currentDate = _selectedEventDate ?? today;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _selectedEventDate = picked;
        _eventDateController.text = DateFormat('dd/MM/yyyy').format(picked);
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
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          eventDate: _selectedEventDate!,
          maxGiftValue: _defineGiftValue ? _giftValue.round() : null,
        );

        await widget.eventService.createEvent(newEventDto);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento criado com sucesso!')),
        );
        context.pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar evento: $e')),
        );
        context.pop(false);
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

    _sliderMaxController = TextEditingController(text: _sliderMax.toString());
    _sliderMaxController.addListener(() {
      final parsed = int.tryParse(_sliderMaxController.text);
      if (parsed == null) return;

      int normalized = parsed;
      if (normalized < 50) normalized = 50;
      normalized = ((normalized + 5) ~/ 10) * 10;

      if (normalized != parsed) {
        _sliderMaxController.text = normalized.toString();
        _sliderMaxController.selection = TextSelection.fromPosition(
          TextPosition(offset: _sliderMaxController.text.length),
        );
      }

      setState(() {
        _sliderMax = normalized;
        if (_giftValue > _sliderMax) _giftValue = _sliderMax.toDouble();
        _giftValue = ((_giftValue / 10).round() * 10).clamp(0, _sliderMax).toDouble();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _eventDateController.dispose();
    _sliderMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Evento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Título'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: _inputDecoration('Descrição'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eventDateController,
                decoration: _inputDecoration('Data do Evento', icon: Icons.calendar_today),
                readOnly: true,
                onTap: () => _selectDate(context),
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
                          decoration: _inputDecoration('Máx.'),
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

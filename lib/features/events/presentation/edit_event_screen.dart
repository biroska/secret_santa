import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../dtos/event_card_dto.dart';
import '../../../services/firestore/event_service.dart';
import 'incluir_dependente_screen.dart';
import 'event_title_card.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({
    super.key,
    required this.event,
    required this.onParticipantsChanged,
  });

  final EventCardDto event;
  final Future<void> Function() onParticipantsChanged;

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _giftValueController = TextEditingController();
  late DateTime _eventDate;
  late List<Map<String, dynamic>> _participants;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _eventDate = widget.event.eventDate ?? DateTime.now();
    _participants = widget.event.participants
        .map((participant) => Map<String, dynamic>.from(participant))
        .toList();
    _giftValueController.text = widget.event.maxGiftValue?.toString() ?? '';
  }

  @override
  void dispose() {
    _giftValueController.dispose();
    super.dispose();
  }

  Future<void> _selectEventDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selected != null) {
      setState(() => _eventDate = selected);
    }
  }

  Future<void> _save() async {
    final rawGiftValue = _giftValueController.text.trim();
    final giftValue = rawGiftValue.isEmpty ? null : int.tryParse(rawGiftValue);
    if (rawGiftValue.isNotEmpty && (giftValue == null || giftValue < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor de presente válido.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _eventService.updateEditableEvent(
        widget.event.id,
        eventDate: _eventDate,
        maxGiftValue: giftValue,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento atualizado com sucesso.')),
      );
      _hasChanges = true;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar as alterações: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _manageParticipant(
    Map<String, dynamic> participant,
    String action,
  ) async {
    final participantId = participant['participantId'] as String?;
    if (participantId == null || participantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar o participante.'),
        ),
      );
      return;
    }

    if (action == 'edit-dependent') {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => IncluirDependenteScreen(
            eventId: widget.event.id,
            eventParticipants: _participants,
            dependentToEdit: participant,
          ),
        ),
      );
      if (changed == true) {
        _hasChanges = true;
        await _reloadParticipants();
        await widget.onParticipantsChanged();
      }
      return;
    }

    final isDependent = participant['isDependent'] == true;
    final name = (participant['name'] as String?)?.trim().isNotEmpty == true
        ? (participant['name'] as String).trim()
        : 'este participante';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isDependent ? 'Remover dependente?' : 'Remover participante?',
        ),
        content: Text('Deseja remover $name do evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      if (isDependent) {
        await _eventService.removeDependentParticipant(
          widget.event.id,
          participantId,
        );
      } else {
        await _eventService.removeEventParticipant(
          widget.event.id,
          participantId,
        );
      }
      _hasChanges = true;
      await _reloadParticipants();
      if (!mounted) return;
      await widget.onParticipantsChanged();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participante removido com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível remover: $e')));
    }
  }

  Future<void> _reloadParticipants() async {
    final event = await _eventService.getEventById(widget.event.id);
    if (!mounted || event == null) return;
    setState(() {
      _participants = event.participants
          .map((participant) => Map<String, dynamic>.from(participant))
          .toList();
    });
  }

  void _close() => Navigator.of(context).pop(_hasChanges);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        title: const Text('Editar evento'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _close,
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 18),
            EventTitleCard(
              event: widget.event,
              isAdmin: false,
              includeOuterPadding: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Data do evento'),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(_eventDate),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _selectEventDate,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _giftValueController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Valor máximo do presente',
                            prefixText: 'R\$ ',
                            helperText:
                                'Deixe vazio para não definir um limite.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _save,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Salvar alterações'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Participantes (${_participants.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._participants.map(_buildParticipantTile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTile(Map<String, dynamic> participant) {
    return EditEventParticipantCard(
      participant: participant,
      adminId: widget.event.adminId,
      onRemove: () => _manageParticipant(participant, 'remove'),
      onEditDependent: () => _manageParticipant(participant, 'edit-dependent'),
    );
  }
}

class EditEventParticipantCard extends StatelessWidget {
  const EditEventParticipantCard({
    super.key,
    required this.participant,
    required this.adminId,
    required this.onRemove,
    required this.onEditDependent,
  });

  final Map<String, dynamic> participant;
  final String adminId;
  final VoidCallback onRemove;
  final VoidCallback onEditDependent;

  @override
  Widget build(BuildContext context) {
    final participantId = participant['participantId'] as String? ?? '';
    final isDependent = participant['isDependent'] == true;
    final isAdmin =
        participant['role'] == 'ADMIN' || participant['userId'] == adminId;
    final name = (participant['name'] as String?)?.trim().isNotEmpty == true
        ? (participant['name'] as String).trim()
        : (participant['userId'] as String? ?? participantId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (!isAdmin)
            IconButton(
              tooltip: isDependent
                  ? 'Remover dependente'
                  : 'Remover participante',
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFCF2A2A),
              ),
            ),
          if (isDependent)
            IconButton(
              tooltip: 'Editar dependente',
              onPressed: onEditDependent,
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF1D7B72)),
            ),
          CircleAvatar(
            backgroundColor: const Color(0xFFE5E7EB),
            child: Icon(
              isDependent ? Icons.child_care : Icons.person_outline,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin
                      ? 'Organizador'
                      : (isDependent ? 'Dependente' : 'Participante'),
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

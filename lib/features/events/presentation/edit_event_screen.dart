import '../../../widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_navigation.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/user_avatar.dart';
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
      AppSnackBar.error(context, 'Informe um valor de presente válido.');
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
      AppSnackBar.success(context, 'Evento atualizado com sucesso.');
      _hasChanges = true;
      AppNavigation.back(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Não foi possível salvar as alterações: $e');
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
      AppSnackBar.error(
        context,
        'Não foi possível identificar o participante.',
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
            event: widget.event,
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
      AppSnackBar.success(context, 'Participante removido com sucesso.');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Não foi possível remover: $e');
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

  void _close() => AppNavigation.back(context, _hasChanges);

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
                  AppCard(
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
                          decoration: InputDecoration(
                            labelText: 'Valor máximo do presente',
                            hintText: 'Valor máximo do presente',
                            prefixText: 'R\$ ',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            helperText:
                                'Deixe vazio para não definir um limite.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE6E8EC),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE6E8EC),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
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
                    'Participantes ${_participants.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
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
    final role = (participant['role'] as String? ?? '').toUpperCase();
    final isAdmin = role == 'ADMIN' || participant['userId'] == adminId;
    final isBadgeDependent = isDependent || role == 'DEPENDENT';
    final name = (participant['name'] as String?)?.trim().isNotEmpty == true
        ? (participant['name'] as String).trim()
        : (participant['userId'] as String? ?? participantId);
    final photoUrl = (participant['photoUrl'] as String?) ?? '';
    final canSortResponsible = participant['canSortResponsible'] == true;
    final warningText = isDependent && !canSortResponsible
        ? 'Não pode sortear os responsáveis'
        : null;
    final badgeLabel = isAdmin
        ? 'Organizador'
        : (isBadgeDependent ? 'Dependente' : 'Participante');
    final badgeColor = isAdmin
        ? const Color(0xFFE9F3FA)
        : (isBadgeDependent
              ? const Color(0xFFFCEFD9)
              : const Color(0xFFE2F0E2));
    final badgeTextColor = isAdmin
        ? const Color(0xFF2C6F9F)
        : (isBadgeDependent
              ? const Color(0xFFB07A1E)
              : const Color(0xFF3D8F3D));

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (!isAdmin)
            IconButton(
              tooltip: isDependent
                  ? 'Remover dependente'
                  : 'Remover participante',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_forever_outlined,
                color: Color(0xFFCF2A2A),
                size: 26,
              ),
            ),
          if (isDependent)
            IconButton(
              tooltip: 'Editar dependente',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              visualDensity: VisualDensity.compact,
              onPressed: onEditDependent,
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF1D7B72),
                size: 26,
              ),
            ),
          UserAvatar(photoUrl: photoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1B1B1B),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (warningText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      warningText,
                      style: const TextStyle(
                        color: Color(0xFFCF2A2A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: badgeTextColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: badgeTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

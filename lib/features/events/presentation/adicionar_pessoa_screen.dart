import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/participant_invite_model.dart';
import '../../../services/mock_invite_service.dart';
import '../../../dtos/event_card_dto.dart';
import '../../../services/firestore/event_service.dart';
import 'event_title_card.dart';
import 'incluir_dependente_screen.dart';

class AdicionarPessoaScreen extends StatefulWidget {
  final String eventId;
  final ParticipantInviteModel? model;

  const AdicionarPessoaScreen({super.key, required this.eventId, this.model});

  @override
  State<AdicionarPessoaScreen> createState() => _AdicionarPessoaScreenState();
}

class _AdicionarPessoaScreenState extends State<AdicionarPessoaScreen> {
  ParticipantInviteModel? _model;
  EventCardDto? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.model != null) {
      _model = widget.model;
    } else {
      final service = MockInviteService();
      _model = await service.getInviteForEvent(widget.eventId);
    }

    // carregar dados do evento para exibir o título reutilizável
    try {
      final eventService = EventService();
      _event = await eventService.getEventById(widget.eventId);
    } catch (e) {
      // ignorar erro e permitir que a tela continue com mock
      debugPrint('Erro ao carregar evento em AdicionarPessoaScreen: $e');
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  void _copyLink() {
    if (_model == null) return;
    Clipboard.setData(ClipboardData(text: _model!.inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado')));
  }

  void _shareLink() {
    // Implementar compartilhamento real futuramente; por ora mostra snackbar
    if (_model == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compartilhar: ${_model!.inviteLink}')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar participante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_event != null)
                      EventTitleCard(
                        event: _event!,
                        isAdmin: false,
                        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                        includeOuterPadding: false,
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Participantes entram por QR Code ou link. Dependentes são cadastrados por você.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9F3FA),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.qr_code, color: Color(0xFF2C6F9F)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_model!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(_model!.subtitle, style: const TextStyle(color: Color(0xFF667085))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(8),
                                child: _event != null
                                                                    ? Image.network(
                                                                        'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(_event!.id)}',
                                                                        width: 200,
                                                                        height: 200,
                                                                        fit: BoxFit.cover,
                                                                      )
                                                                    : Image.asset(
                                                                        _model!.qrAsset,
                                                                        height: 200,
                                                                        width: 200,
                                                                        fit: BoxFit.cover,
                                                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _copyLink,
                                    icon: const Icon(Icons.copy_outlined),
                                    label: const Text('Copiar link'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _shareLink,
                                    icon: const Icon(Icons.share_outlined),
                                    label: const Text('Compartilhar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_outline, color: Color(0xFF8A5B00))),
                        title: const Text('Dependente'),
                        subtitle: const Text('Inclua um dependente'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => IncluirDependenteScreen(
                                eventId: widget.eventId,
                                eventParticipants: _event?.participants ?? const [],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

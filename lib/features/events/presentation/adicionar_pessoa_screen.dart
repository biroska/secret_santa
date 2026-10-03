import '../../../widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/app_navigation.dart';
import '../../../dtos/event_card_dto.dart';
import '../../../services/firestore/event_service.dart';
import 'event_title_card.dart';
import 'incluir_dependente_screen.dart';

class AdicionarPessoaScreen extends StatefulWidget {
  final String eventId;

  const AdicionarPessoaScreen({super.key, required this.eventId});

  @override
  State<AdicionarPessoaScreen> createState() => _AdicionarPessoaScreenState();
}

class _AdicionarPessoaScreenState extends State<AdicionarPessoaScreen> {
  static const String _inviteTitle = 'Participante';
  static const String _inviteSubtitle =
      'Peça para escanear o QR Code ou envie o link do evento.';

  EventCardDto? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_loading) setState(() => _loading = true);

    EventCardDto? event;
    try {
      event = await EventService().getEventById(widget.eventId);
    } catch (e) {
      debugPrint('Erro ao carregar evento em AdicionarPessoaScreen: $e');
    }

    if (!mounted) return;
    setState(() {
      _event = event;
      _loading = false;
    });
    if (event == null) {
      AppSnackBar.error(context, 'Não foi possível carregar o evento.');
    }
  }

  /// Domínio do Firebase Hosting que responde por Android App Links
  /// (`https://galdinos-secret-santa.web.app/event/eventId`).
  static const String _appLinkHost = 'galdinos-secret-santa.web.app';

  /// Link de convite compartilhável. Usa uma URL https (clicável em
  /// WhatsApp/SMS) que abre o app diretamente via Android App Link verificado
  /// e cai para a página de instalação (`public/install.html`) quando o app
  /// não está instalado.
  String get _inviteLink => 'https://$_appLinkHost/event/${_event?.id ?? ''}';

  Future<void> _shareLink() async {
    if (_event == null) {
      return;
    }

    final inviteLink = _inviteLink;
    final message = 'Participe do meu amigo secreto: $inviteLink';
    final whatsappUri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(message)}',
    );

    try {
      final canOpenWhatsapp = await canLaunchUrl(whatsappUri);
      if (canOpenWhatsapp) {
        final opened = await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        if (opened) {
          return;
        }
      }

      await Share.share(message);
    } catch (e) {
      if (!mounted) {
        return;
      }
      AppSnackBar.error(context, 'Não foi possível compartilhar o convite: $e');
    }
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível carregar o evento.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar participante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => AppNavigation.back(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
          ? _buildLoadError()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EventTitleCard(
                      event: _event!,
                      isAdmin: false,
                      backgroundColor: Theme.of(
                        context,
                      ).appBarTheme.backgroundColor,
                      includeOuterPadding: false,
                    ),
                    const SizedBox(height: 18),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                                  child: const Icon(
                                    Icons.qr_code,
                                    color: Color(0xFF2C6F9F),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _inviteTitle,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _inviteSubtitle,
                                        style: const TextStyle(
                                          color: Color(0xFF667085),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(_inviteLink)}',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                      ? child
                                      : const SizedBox(
                                          width: 200,
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                  errorBuilder: (context, error, stack) =>
                                      const SizedBox(
                                        width: 200,
                                        height: 200,
                                        child: Center(
                                          child: Text(
                                            'Não foi possível carregar o QR Code.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            if (_event?.name.isNotEmpty ?? false) ...[
                              const SizedBox(height: 10),
                              Text(
                                _event!.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        AppNavigation.back(context),
                                    style: const ButtonStyle(
                                      minimumSize: WidgetStatePropertyAll(
                                        Size.fromHeight(48),
                                      ),
                                      padding: WidgetStatePropertyAll(
                                        EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _shareLink(),
                                    icon: const Icon(Icons.share_outlined),
                                    style: const ButtonStyle(
                                      minimumSize: WidgetStatePropertyAll(
                                        Size.fromHeight(48),
                                      ),
                                      padding: WidgetStatePropertyAll(
                                        EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                    ),
                                    label: const Text(
                                      'Compartilhar',
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(
                            Icons.person_outline,
                            color: Color(0xFF8A5B00),
                          ),
                        ),
                        title: const Text('Dependente'),
                        subtitle: const Text('Inclua um dependente'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => IncluirDependenteScreen(
                                    eventId: widget.eventId,
                                    eventParticipants:
                                        _event?.participants ?? const [],
                                    event: _event,
                                  ),
                                ),
                              )
                              .then((changed) {
                                if (changed == true && context.mounted) {
                                  AppNavigation.back(context, true);
                                }
                              });
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

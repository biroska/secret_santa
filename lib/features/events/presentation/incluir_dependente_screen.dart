import 'package:flutter/material.dart';

class IncluirDependenteScreen extends StatefulWidget {
  final List<Map<String, dynamic>> eventParticipants;

  const IncluirDependenteScreen({
    super.key,
    this.eventParticipants = const [],
  });

  @override
  State<IncluirDependenteScreen> createState() => _IncluirDependenteScreenState();
}

class _IncluirDependenteScreenState extends State<IncluirDependenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _responsaveisSelecionados = [];
  bool _permitirSortearResponsaveis = false;

  List<Map<String, dynamic>> get _responsaveisDisponiveis {
    final query = _searchController.text.trim().toLowerCase();
    final base = widget.eventParticipants.where((participant) {
      final userId = ((participant['userId'] as String?) ?? '').trim();
      final name = ((participant['name'] as String?) ?? userId).trim();
      if (query.isEmpty) return true;
      return name.toLowerCase().contains(query) || userId.toLowerCase().contains(query);
    }).toList();

    return base;
  }

  String _getParticipantName(Map<String, dynamic> participant) {
    final rawName = (participant['name'] as String?)?.trim();
    if (rawName != null && rawName.isNotEmpty) return rawName;
    final userId = (participant['userId'] as String?)?.trim();
    if (userId != null && userId.isNotEmpty) return userId;
    return 'Participante';
  }

  String _getParticipantRole(Map<String, dynamic> participant) {
    final role = ((participant['role'] as String?) ?? '').toUpperCase();
    if (role == 'ADMIN') return 'Organizador';
    return 'Participante';
  }

  bool _isSelected(Map<String, dynamic> participant) {
    final userId = (participant['userId'] as String?) ?? '';
    return _responsaveisSelecionados.any((item) => (item['userId'] as String? ?? '') == userId);
  }

  void _toggleResponsavel(Map<String, dynamic> participant) {
    final userId = (participant['userId'] as String?) ?? '';
    setState(() {
      if (_isSelected(participant)) {
        _responsaveisSelecionados.removeWhere((item) => (item['userId'] as String? ?? '') == userId);
      } else {
        _responsaveisSelecionados.add(participant);
      }
    });
  }

  Widget _buildResponsibleItem({
    required String name,
    required String role,
    required bool selected,
    required VoidCallback onToggle,
  }) {
    final badgeColor = role == 'Organizador'
        ? const Color(0xFFD9E9E6)
        : const Color(0xFFE2F0E2);
    final badgeTextColor = role == 'Organizador'
        ? const Color(0xFF1D7B72)
        : const Color(0xFF3D8F3D);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => onToggle(),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Color(0xFF667085)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF1B1B1B),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveDependente() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    if (_responsaveisSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um responsável.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dependente salvo com sucesso.')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        title: const Text('Adicionar participante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: backgroundColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Novo dependente',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            labelText: 'Nome do dependente',
                            hintText: 'Ex.: Alice Galdino',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: backgroundColor, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.redAccent),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'O nome do dependente é obrigatório.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Responsáveis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            Text(
                              '${_responsaveisSelecionados.length} selecionado(s)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar participante...',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: backgroundColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_responsaveisDisponiveis.isEmpty)
                          Container(
                           width: double.infinity,
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(14),
                           ),
                           child: const Text(
                             'Nenhum participante disponível para ser responsável.',
                             style: TextStyle(color: Color(0xFF667085)),
                           ),
                          )
                        else
                          ListView.builder(
                           shrinkWrap: true,
                           physics: const NeverScrollableScrollPhysics(),
                           itemCount: _responsaveisDisponiveis.length,
                           itemBuilder: (context, index) {
                             final participant = _responsaveisDisponiveis[index];
                             final name = _getParticipantName(participant);
                             final role = _getParticipantRole(participant);

                             return _buildResponsibleItem(
                               name: name,
                               role: role,
                               selected: _isSelected(participant),
                               onToggle: () => _toggleResponsavel(participant),
                             );
                           },
                          ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7EEF4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: SizedBox(
                                  width: 44,
                                  child: Switch(
                                    value: _permitirSortearResponsaveis,
                                    onChanged: (value) => setState(() => _permitirSortearResponsaveis = value),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Permitir sortear os responsáveis',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Habilite para que o dependente possa sortear um de seus responsáveis',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveDependente,
                      style: FilledButton.styleFrom(
                        backgroundColor: backgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Salvar dependente'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

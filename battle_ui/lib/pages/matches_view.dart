import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../nav.dart';

class MatchesView extends StatefulWidget {
  const MatchesView({super.key});

  @override
  State<MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<MatchesView> {
  String _selectedTeam = 'Equipo Aleatorio';
  String? _generatedBattleCode;

  final List<String> _teams = const [
    'Equipo Aleatorio',
    'Equipo Lluvia',
    'Trick Room Core',
  ];

  String _generateBattleCode() {
    final r = Random();
    return '${r.nextInt(900) + 100}-${r.nextInt(900) + 100}';
  }

  void _showJoinBattleDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.link, color: AppColors.secondary),
        ),
        title: const Text('Buscar batalla'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ingresa el código de la batalla',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [_BattleCodeFormatter()],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: AppColors.secondary,
                ),
                decoration: const InputDecoration(hintText: '000-000'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length == 6) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Buscando batalla: ${controller.text}')),
                );
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Código inválido. Debe tener 6 dígitos.')),
                );
              }
            },
            child: const Text('Conectar'),
          ),
        ],
      ),
    );
  }

  void _showCreatedDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Icons.celebration, color: AppColors.primary),
        ),
        title: const Text('Combate creado'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Comparte este código con tu oponente',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Código copiado al portapapeles')),
                  );
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.copy, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca para copiar',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('${AppRoutes.battle}?code=$code');
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Ir al combate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Arena de batalla',
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Encuentra un oponente y demuestra tus habilidades tácticas.',
            style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final isWide = c.maxWidth > 900;
                if (!isWide) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTeamSelection(),
                        const SizedBox(height: 20),
                        _buildActionsCard(),
                        const SizedBox(height: 20),
                        _buildActiveBattlesCard(),
                        const SizedBox(height: 20),
                        _buildHistoryCard(),
                      ],
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildTeamSelection()),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildActionsCard(),
                          const SizedBox(height: 20),
                          _buildActiveBattlesCard(),
                          const SizedBox(height: 20),
                          _buildHistoryCard(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelection() {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Tu equipo', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            ..._teams.map((t) {
              final selected = _selectedTeam == t;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => setState(() => _selectedTeam = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.outlineVariant,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected ? Icons.shield : Icons.shield_outlined,
                            color: selected ? AppColors.primary : AppColors.onSurfaceMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t,
                              style: TextStyle(
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? AppColors.onSurface : AppColors.onSurfaceMuted,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () {
                final code = _generateBattleCode();
                setState(() => _generatedBattleCode = code);
                _showCreatedDialog(code);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Crear combate', style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _showJoinBattleDialog,
              icon: const Icon(Icons.search),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Buscar batalla', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBattlesCard() {
    final text = Theme.of(context).textTheme;
    final activeBattles = const [
      {'id': '482-913', 'trainerA': 'Ash', 'trainerB': 'Gary'},
      {'id': '157-204', 'trainerA': 'Misty', 'trainerB': 'Brock'},
      {'id': '739-061', 'trainerA': 'Red', 'trainerB': 'Blue'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.bolt, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Combates activos', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            if (activeBattles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.sports_esports_outlined,
                        color: AppColors.onSurfaceMuted, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      'No tienes combates activos',
                      style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              )
            else
              ...activeBattles.map((b) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => context.push('${AppRoutes.battle}?code=${b['id']}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID #${b['id']}',
                                    style: text.labelMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          b['trainerA']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          'vs',
                                          style: text.labelSmall?.copyWith(
                                            color: AppColors.onSurfaceMuted,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          b['trainerB']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: AppColors.onSurfaceMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    final text = Theme.of(context).textTheme;
    final history = const [
      {'result': 'V', 'opponent': 'Entrenador A'},
      {'result': 'V', 'opponent': 'Entrenador B'},
      {'result': 'D', 'opponent': 'Entrenador C'},
      {'result': 'V', 'opponent': 'Entrenador D'},
      {'result': 'V', 'opponent': 'Entrenador E'},
      {'result': 'D', 'opponent': 'Entrenador F'},
      {'result': 'V', 'opponent': 'Entrenador G'},
      {'result': 'V', 'opponent': 'Entrenador H'},
    ];
    final wins = history.where((h) => h['result'] == 'V').length;
    final losses = history.length - wins;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Text('Historial', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _StatChip(label: 'Victorias', value: wins, color: AppColors.success)),
                const SizedBox(width: 10),
                Expanded(child: _StatChip(label: 'Derrotas', value: losses, color: AppColors.danger)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Últimas batallas',
              style: text.bodySmall?.copyWith(color: AppColors.onSurfaceMuted, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: history.map((b) {
                final isV = b['result'] == 'V';
                final c = isV ? AppColors.success : AppColors.danger;
                return Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: c.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    b['result']!,
                    style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(
            '$value',
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formatter para códigos XXX-XXX
class _BattleCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 6 ? digits.substring(0, 6) : digits;
    String formatted = limited.length <= 3
        ? limited
        : '${limited.substring(0, 3)}-${limited.substring(3)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

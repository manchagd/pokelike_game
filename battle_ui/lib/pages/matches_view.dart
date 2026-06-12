import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../nav.dart';
import '../utils/battle_socket_service.dart';

class MatchesView extends StatefulWidget {
  const MatchesView({super.key});

  @override
  State<MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<MatchesView> {
  String _selectedTeam = 'Equipo Aleatorio';

  List<String> _getTeams(Map<String, dynamic> profile) {
    final rawTeams = (profile['teams'] as List?)?.cast<Map>() ?? [];
    return ['Equipo Aleatorio'] + rawTeams.map((t) => (t['name'] as String?) ?? 'Equipo').toList();
  }

  String _getOpponentDisplay(dynamic opponentData) {
    if (opponentData == null) return 'Oponente';
    if (opponentData is String) return opponentData;
    if (opponentData is List) {
      if (opponentData.isEmpty) return 'Oponente';
      return opponentData.map((op) {
        if (op is Map) {
          final name = op['name'] ?? '';
          final team = op['team'] ?? '';
          return team.isNotEmpty ? '$name ($team)' : name;
        }
        return op.toString();
      }).join(', ');
    }
    if (opponentData is Map) {
      final name = opponentData['name'] ?? '';
      final team = opponentData['team'] ?? '';
      return team.isNotEmpty ? '$name ($team)' : name;
    }
    return opponentData.toString();
  }

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
    final socketService = context.watch<BattleSocketService>();
    final profile = socketService.currentPlayer;
    final activeUsers = socketService.activeUsersCount;

    // MatchesView is only rendered by HomePage when profile is non-null
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final teamsList = _getTeams(profile);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arena de batalla',
                style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$activeUsers en línea',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Hola, ${profile["name"]}. Encuentra un oponente y demuestra tus habilidades tácticas.',
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
                        _buildTeamSelection(teamsList),
                        const SizedBox(height: 20),
                        _buildActionsCard(),
                        const SizedBox(height: 20),
                        _buildActiveBattlesCard(socketService, profile),
                        const SizedBox(height: 20),
                        _buildHistoryCard(profile),
                      ],
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: _buildTeamSelection(teamsList),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildActionsCard(),
                            const SizedBox(height: 20),
                            _buildActiveBattlesCard(socketService, profile),
                            const SizedBox(height: 20),
                            _buildHistoryCard(profile),
                          ],
                        ),
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

  Widget _buildTeamSelection(List<String> teams) {
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
            ...teams.map((t) {
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

  void _showCreateBattleDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateBattleDialog(
        socketService: context.read<BattleSocketService>(),
        onGoToBattle: (code) {
          context.push('${AppRoutes.battle}?code=$code');
        },
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
              onPressed: _showCreateBattleDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Crear combate', style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => _JoinBattleDialog(
                    socketService: context.read<BattleSocketService>(),
                    onJoinedBattle: (code) {
                      context.push('${AppRoutes.battle}?code=$code');
                    },
                  ),
                );
              },
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

  Widget _buildActiveBattlesCard(BattleSocketService socketService, Map<String, dynamic> profile) {
    final text = Theme.of(context).textTheme;
    final activeBattles = socketService.activeBattles;

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
                final code = b['id'] as String?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () {
                        if (code != null) {
                          context.push('${AppRoutes.battle}?code=$code');
                        }
                      },
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
                                    'ID #${code ?? '---'}',
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
                                          profile['name'] ?? 'Tú',
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
                                          _getOpponentDisplay(b['opponent'] ?? b['player']),
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

  Widget _buildHistoryCard(Map<String, dynamic> profile) {
    final text = Theme.of(context).textTheme;
    final historyData = profile['battle_history'] as Map<String, dynamic>?;
    final wins = historyData?['victories'] as int? ?? 0;
    final losses = historyData?['defeats'] as int? ?? 0;
    final historyList = (historyData?['history'] as List?)?.cast<String>() ?? [];

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
              children: historyList.map((result) {
                final isV = result == 'V' || result == 'win' || result == 'W';
                final displayChar = (result.isNotEmpty) ? result[0].toUpperCase() : 'V';
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
                    displayChar,
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

class _BattleCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, newValue) {
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

class _CreateBattleDialog extends StatefulWidget {
  final BattleSocketService socketService;
  final ValueChanged<String> onGoToBattle;

  const _CreateBattleDialog({
    required this.socketService,
    required this.onGoToBattle,
  });

  @override
  State<_CreateBattleDialog> createState() => _CreateBattleDialogState();
}

class _CreateBattleDialogState extends State<_CreateBattleDialog> {
  StreamSubscription<String>? _subscription;
  String? _battleCode;

  @override
  void initState() {
    super.initState();
    _subscription = widget.socketService.battleCreatedEvents.listen(
      (code) {
        if (mounted) {
          setState(() {
            _battleCode = code;
          });
        }
      },
    );
    // Request creation
    widget.socketService.createBattle();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _battleCode;

    if (code == null) {
      return AlertDialog(
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Creando batalla...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Por favor, espera mientras preparamos la arena.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      );
    }

    return AlertDialog(
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onGoToBattle(code);
          },
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Ir al combate'),
        ),
      ],
    );
  }
}

class _JoinBattleDialog extends StatefulWidget {
  final BattleSocketService socketService;
  final ValueChanged<String> onJoinedBattle;

  const _JoinBattleDialog({
    required this.socketService,
    required this.onJoinedBattle,
  });

  @override
  State<_JoinBattleDialog> createState() => _JoinBattleDialogState();
}

class _JoinBattleDialogState extends State<_JoinBattleDialog> {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<String>? _subscription;
  bool _isConnecting = false;
  String? _targetCode;

  @override
  void initState() {
    super.initState();
    _subscription = widget.socketService.battleJoinedEvents.listen((code) {
      if (mounted && _isConnecting && code == _targetCode) {
        widget.onJoinedBattle(code);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleConnect() {
    final code = _controller.text.trim();
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 6) {
      setState(() {
        _isConnecting = true;
        _targetCode = code;
      });
      widget.socketService.joinBattle(code);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código inválido. Debe tener 6 dígitos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          _isConnecting ? Icons.sync : Icons.link,
          color: AppColors.secondary,
        ),
      ),
      title: Text(_isConnecting ? 'Conectando...' : 'Buscar batalla'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isConnecting
                  ? 'Uniéndose al combate $_targetCode...'
                  : 'Ingresa el código de la batalla',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
              textAlign: _isConnecting ? TextAlign.center : TextAlign.start,
            ),
            const SizedBox(height: 16),
            if (!_isConnecting)
              TextField(
                controller: _controller,
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
                onSubmitted: (_) => _handleConnect(),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: AppColors.secondary),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isConnecting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (!_isConnecting)
          FilledButton(
            onPressed: _handleConnect,
            child: const Text('Conectar'),
          ),
      ],
    );
  }
}

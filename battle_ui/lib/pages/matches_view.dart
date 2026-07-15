import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mix/mix.dart';
import '../theme.dart';
import '../nav.dart';
import '../utils/battle_socket_service.dart';
import '../utils/pokemon_type_icons.dart';
final _onlineBadgeContainerStyle = BoxStyler()
  .padding(EdgeInsetsGeometryMix.symmetric(horizontal: 12, vertical: 6))
  .borderRadius(BorderRadiusGeometryMix.circular(20))
  .color(AppColors.success.withValues(alpha: 0.1))
  .border(BorderMix.all(BorderSideMix(color: AppColors.success.withValues(alpha: 0.3))));

final _onlineIndicatorDotStyle = BoxStyler()
  .width(8)
  .height(8)
  .color(AppColors.success)
  .borderRadius(BorderRadiusGeometryMix.circular(4));

final _onlineBadgeTextStyle = TextStyler()
  .color(AppColors.success)
  .fontSize(12)
  .fontWeight(FontWeight.w700);

final _shieldIconBackgroundStyle = BoxStyler()
  .width(36)
  .height(36)
  .color(AppColors.secondary.withValues(alpha: 0.16))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.sm));

BoxStyler _teamRowStyle(bool selected) => BoxStyler()
  .padding(EdgeInsetsGeometryMix.symmetric(horizontal: 16, vertical: 14))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .color(selected ? AppColors.primary.withValues(alpha: 0.10) : AppColors.surfaceHigh)
  .border(BorderMix.all(BorderSideMix(
    color: selected ? AppColors.primary : AppColors.outlineVariant,
    width: selected ? 1.5 : 1.0,
  )))
  .onHovered(BoxStyler().color(selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.outlineVariant.withValues(alpha: 0.1)))
  .animate(AnimationConfig.ease(const Duration(milliseconds: 150)));

TextStyler _teamRowTextStyle(bool selected) => TextStyler()
  .fontWeight(selected ? FontWeight.w700 : FontWeight.w500)
  .color(selected ? AppColors.onSurface : AppColors.onSurfaceMuted)
  .fontSize(15);

BoxStyler _pokemonChipStyle(Color c1, Color c2) => BoxStyler()
  .padding(EdgeInsetsGeometryMix.symmetric(horizontal: 10, vertical: 5))
  .borderRadius(BorderRadiusGeometryMix.circular(16))
  .linearGradient(
    colors: [
      c1.withValues(alpha: 0.14),
      c2.withValues(alpha: 0.14),
    ],
  )
  .border(BorderMix.all(BorderSideMix(
    color: Color.lerp(c1, c2, 0.5)!.withValues(alpha: 0.4),
    width: 1.0,
  )));

final _pokemonChipTextStyle = TextStyler()
  .fontSize(12)
  .fontWeight(FontWeight.w600);

final _noTeamsAlertStyle = BoxStyler()
  .padding(EdgeInsetsGeometryMix.all(12))
  .color(AppColors.danger.withValues(alpha: 0.12))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .border(BorderMix.all(BorderSideMix(color: AppColors.danger.withValues(alpha: 0.4))));

final _noTeamsAlertTextStyle = TextStyler()
  .color(AppColors.danger)
  .fontSize(13)
  .fontWeight(FontWeight.w500);

final _activeBattlesIconBackgroundStyle = BoxStyler()
  .width(36)
  .height(36)
  .color(AppColors.primary.withValues(alpha: 0.16))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.sm));

final _noActiveBattlesContainerStyle = BoxStyler()
  .width(double.infinity)
  .padding(EdgeInsetsGeometryMix.symmetric(vertical: 28))
  .alignment(Alignment.center)
  .color(AppColors.surfaceHigh)
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .border(BorderMix.all(BorderSideMix(color: AppColors.outlineVariant)));

TextStyler _noActiveBattlesTextStyle(double fontSize) => TextStyler()
  .color(AppColors.onSurfaceMuted)
  .fontSize(fontSize);

final _activeBattleRowStyle = BoxStyler()
  .padding(EdgeInsetsGeometryMix.symmetric(horizontal: 14, vertical: 12))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .color(AppColors.surfaceHigh)
  .border(BorderMix.all(BorderSideMix(color: AppColors.outlineVariant)))
  .onHovered(BoxStyler().color(AppColors.outlineVariant.withValues(alpha: 0.1)))
  .animate(AnimationConfig.ease(const Duration(milliseconds: 150)));

TextStyler _activeBattleRowIdStyle(double fontSize) => TextStyler()
  .fontSize(fontSize)
  .color(AppColors.primary)
  .fontWeight(FontWeight.w700)
  .letterSpacing(0.5);

BoxStyler _resultBadgeStyle(Color c) => BoxStyler()
  .width(28)
  .height(28)
  .alignment(Alignment.center)
  .color(c.withValues(alpha: 0.18))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.sm))
  .border(BorderMix.all(BorderSideMix(color: c.withValues(alpha: 0.5))));

TextStyler _resultBadgeTextStyle(Color c) => TextStyler()
  .color(c)
  .fontWeight(FontWeight.w800)
  .fontSize(12);

BoxStyler _statChipStyle(Color color) => BoxStyler()
  .padding(EdgeInsetsGeometryMix.symmetric(horizontal: 14, vertical: 12))
  .color(color.withValues(alpha: 0.12))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .border(BorderMix.all(BorderSideMix(color: color.withValues(alpha: 0.4))));

TextStyler _statValueStyle(Color color) => TextStyler()
  .color(color)
  .fontSize(22)
  .fontWeight(FontWeight.w800);

final _statLabelStyle = TextStyler()
  .color(AppColors.onSurfaceMuted)
  .fontSize(12);

final _dialogIconBackgroundStyle = BoxStyler()
  .padding(EdgeInsetsGeometryMix.all(10))
  .color(AppColors.primary.withValues(alpha: 0.16))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md));

final _dialogCodeContainerStyle = BoxStyler()
  .padding(EdgeInsetsGeometryMix.symmetric(horizontal: 20, vertical: 14))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .color(AppColors.surfaceHigh)
  .border(BorderMix.all(BorderSideMix(color: AppColors.primary.withValues(alpha: 0.4))))
  .onHovered(BoxStyler().color(AppColors.primary.withValues(alpha: 0.08)))
  .animate(AnimationConfig.ease(const Duration(milliseconds: 150)));

final _dialogCodeTextStyle = TextStyler()
  .fontSize(22)
  .fontWeight(FontWeight.w700)
  .letterSpacing(4)
  .color(AppColors.primary);

final _joinDialogIconStyle = BoxStyler()
  .padding(EdgeInsetsGeometryMix.all(10))
  .color(AppColors.secondary.withValues(alpha: 0.16))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md));

class MatchesView extends StatefulWidget {
  const MatchesView({super.key});

  @override
  State<MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<MatchesView> {
  int? _selectedTeamId;

  List<Map<String, dynamic>> _getTeams(Map<String, dynamic> profile) {
    final rawTeams = (profile['teams'] as List?)?.cast<Map>() ?? [];
    final parsedTeams = rawTeams.map((t) => Map<String, dynamic>.from(t)).toList();
    return <Map<String, dynamic>>[
      {
        'id': null,
        'name': 'Equipo Aleatorio',
        'pokemons': <Map<String, dynamic>>[]
      }
    ] + parsedTeams;
  }

  int? _getEffectiveTeamId(Map<String, dynamic> profile) {
    if (_selectedTeamId != null) {
      return _selectedTeamId;
    }
    final rawTeams = (profile['teams'] as List?)?.cast<Map>() ?? [];
    if (rawTeams.isEmpty) return null;
    final parsedTeams = rawTeams.map((t) => Map<String, dynamic>.from(t)).toList();
    final randomIndex = Random().nextInt(parsedTeams.length);
    return parsedTeams[randomIndex]['id'] as int?;
  }


  Widget _buildVSHeader(Map<String, dynamic> b, String currentUserName, TextStyle? vsStyle) {
    final players = (b['players'] as List?)?.cast<Map>() ?? [];
    
    // Find current user's team
    final currentUser = players.firstWhere((p) => p['name'] == currentUserName, orElse: () => {});
    final myGroup = currentUser['team'];

    List<Map> leftPlayers = [];
    List<Map> rightPlayers = [];

    if (myGroup != null && (myGroup == 'A' || myGroup == 'B')) {
      final otherGroup = myGroup == 'A' ? 'B' : 'A';
      leftPlayers = players.where((p) => p['team'] == myGroup).toList();
      rightPlayers = players.where((p) => p['team'] == otherGroup).toList();
    } else {
      // Fallback: current user on the left, anyone else on the right
      leftPlayers = players.where((p) => p['name'] == currentUserName).toList();
      rightPlayers = players.where((p) => p['name'] != currentUserName).toList();
    }

    if (leftPlayers.isEmpty && rightPlayers.isEmpty) {
      // Fallback if players list is empty
      return Row(
        children: [
          Flexible(
            child: Text(
              currentUserName,
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('vs', style: vsStyle),
          ),
          Flexible(
            child: Text(
              'Esperando oponente...',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final leftText = leftPlayers.map((p) => p['name'] ?? '').join(', ');
    final rightText = rightPlayers.isEmpty 
        ? 'Esperando oponente...' 
        : rightPlayers.map((p) => p['name'] ?? '').join(', ');

    return Row(
      children: [
        Flexible(
          child: Text(
            leftText,
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('vs', style: vsStyle),
        ),
        Flexible(
          child: Text(
            rightText,
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
              Box(
                style: _onlineBadgeContainerStyle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Box(style: _onlineIndicatorDotStyle),
                    const SizedBox(width: 8),
                    StyledText(
                      '$activeUsers en línea',
                      style: _onlineBadgeTextStyle,
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
                        _buildActionsCard(profile),
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
                            _buildActionsCard(profile),
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

  Widget _buildTeamSelection(List<Map<String, dynamic>> teams) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Box(
                  style: _shieldIconBackgroundStyle,
                  child: Icon(Icons.shield_outlined, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Tu equipo', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            ...teams.map((t) {
              final id = t['id'] as int?;
              final name = t['name'] as String;
              final selected = _selectedTeamId == id;
              final rawPokemons = t['pokemons'] as List? ?? [];
              final pokemons = rawPokemons.map((p) => Map<String, dynamic>.from(p as Map)).toList();



              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PressableBox(
                  onPress: () => setState(() => _selectedTeamId = id),
                  style: _teamRowStyle(selected),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          selected ? Icons.shield : Icons.shield_outlined,
                          color: selected ? AppColors.primary : AppColors.onSurfaceMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StyledText(
                              name,
                              style: _teamRowTextStyle(selected),
                            ),
                            if (pokemons.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: pokemons.map((p) {
                                  final rawTypes = p['types'] as List? ?? [];
                                  final types = rawTypes.cast<String>();
                                  final colors = types.isEmpty
                                      ? [AppColors.primary]
                                      : types.map((t) => PokemonTypeIcons.getColor(t)).toList();
                                  final c1 = colors[0];
                                  final c2 = colors.length > 1 ? colors[1] : c1;

                                  return Box(
                                    style: _pokemonChipStyle(c1, c2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (types.isNotEmpty) ...[
                                          PokemonTypeIcons.buildSvgIcon(types[0], color: c1, size: 12),
                                          if (types.length > 1) ...[
                                            const SizedBox(width: 3),
                                            PokemonTypeIcons.buildSvgIcon(types[1], color: c2, size: 12),
                                          ],
                                        ] else ...[
                                          Icon(Icons.catching_pokemon, color: c1, size: 12),
                                        ],
                                        const SizedBox(width: 6),
                                        StyledText(
                                          p['name'] ?? '',
                                          style: _pokemonChipTextStyle,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (selected)
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showCreateBattleDialog(int? teamId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateBattleDialog(
        socketService: context.read<BattleSocketService>(),
        teamId: teamId,
        onGoToBattle: (code) {
          context.push('${AppRoutes.battle}?code=$code');
        },
      ),
    );
  }

  Widget _buildActionsCard(Map<String, dynamic> profile) {
    final rawTeams = (profile['teams'] as List?) ?? [];
    final hasNoTeams = rawTeams.isEmpty;
    final teamId = _getEffectiveTeamId(profile);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasNoTeams) ...[
              Box(
                style: _noTeamsAlertStyle,
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StyledText(
                        'Debes registrar al menos un equipo en el Constructor de Equipos para poder combatir.',
                        style: _noTeamsAlertTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: hasNoTeams ? null : () => _showCreateBattleDialog(teamId),
              icon: const Icon(Icons.add_circle_outline),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Crear combate', style: TextStyle(fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: hasNoTeams
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (ctx) => _JoinBattleDialog(
                          socketService: context.read<BattleSocketService>(),
                          teamId: teamId,
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
                Box(
                  style: _activeBattlesIconBackgroundStyle,
                  child: Icon(Icons.bolt, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Combates activos', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            if (activeBattles.isEmpty)
              Box(
                style: _noActiveBattlesContainerStyle,
                child: Column(
                  children: [
                    Icon(Icons.sports_esports_outlined,
                        color: AppColors.onSurfaceMuted, size: 32),
                    const SizedBox(height: 10),
                    StyledText(
                      'No tienes combates activos',
                      style: _noActiveBattlesTextStyle(text.bodyMedium?.fontSize ?? 14.0),
                    ),
                  ],
                ),
              )
            else
              ...activeBattles.map((b) {
                final code = b['id'] as String?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PressableBox(
                    onPress: () {
                      if (code != null) {
                        context.push('${AppRoutes.battle}?code=$code');
                      }
                    },
                    style: _activeBattleRowStyle,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StyledText(
                                'ID #${code ?? '---'}',
                                style: _activeBattleRowIdStyle(text.labelMedium?.fontSize ?? 12.0),
                              ),
                              const SizedBox(height: 4),
                              _buildVSHeader(
                                b,
                                profile['name'] ?? 'Tú',
                                text.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppColors.onSurfaceMuted),
                      ],
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
                Icon(Icons.history, color: AppColors.secondary, size: 20),
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
                return Box(
                  style: _resultBadgeStyle(c),
                  child: StyledText(
                    displayChar,
                    style: _resultBadgeTextStyle(c),
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
    return Box(
      style: _statChipStyle(color),
      child: Row(
        children: [
          StyledText(
            '$value',
            style: _statValueStyle(color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StyledText(
              label,
              style: _statLabelStyle,
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
    final chars = newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final limited = chars.length > 6 ? chars.substring(0, 6) : chars;
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
  final int? teamId;

  const _CreateBattleDialog({
    required this.socketService,
    required this.onGoToBattle,
    required this.teamId,
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
    widget.socketService.createBattle(teamId: widget.teamId);
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
              CircularProgressIndicator(color: AppColors.primary),
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
      icon: Box(
        style: _dialogIconBackgroundStyle,
        child: Icon(Icons.celebration, color: AppColors.primary),
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
            PressableBox(
              onPress: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado al portapapeles')),
                );
              },
              style: _dialogCodeContainerStyle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StyledText(
                    code,
                    style: _dialogCodeTextStyle,
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.copy, color: AppColors.primary, size: 18),
                ],
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
  final int? teamId;

  const _JoinBattleDialog({
    required this.socketService,
    required this.onJoinedBattle,
    required this.teamId,
  });

  @override
  State<_JoinBattleDialog> createState() => _JoinBattleDialogState();
}

class _JoinBattleDialogState extends State<_JoinBattleDialog> {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<String>? _subscription;
  Timer? _timeoutTimer;
  bool _isConnecting = false;
  String? _targetCode;

  @override
  void initState() {
    super.initState();
    _subscription = widget.socketService.battleJoinedEvents.listen((code) {
      final cleanReceived = code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final cleanTarget = _targetCode?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      if (mounted && _isConnecting && cleanReceived == cleanTarget) {
        _subscription?.cancel();
        _subscription = null;
        _timeoutTimer?.cancel();
        _timeoutTimer = null;
        setState(() {
          _isConnecting = false;
        });
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        widget.onJoinedBattle(code);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timeoutTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleConnect() {
    final code = _controller.text.trim();
    final cleanCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (cleanCode.length == 6) {
      setState(() {
        _isConnecting = true;
        _targetCode = code;
      });

      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _isConnecting) {
          setState(() {
            _isConnecting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró un combate con ese ID o expiró el tiempo de espera.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      });

      widget.socketService.joinBattle(code, teamId: widget.teamId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código inválido. Debe tener 6 caracteres.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Box(
        style: _joinDialogIconStyle,
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: AppColors.secondary,
                ),
                decoration: const InputDecoration(hintText: '000-000'),
                onSubmitted: (_) => _handleConnect(),
              )
            else
              Center(
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

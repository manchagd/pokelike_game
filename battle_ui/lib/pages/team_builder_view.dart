import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../utils/battle_socket_service.dart';
import '../utils/pokemon_type_icons.dart';

class TeamBuilderView extends StatefulWidget {
  const TeamBuilderView({super.key});

  @override
  State<TeamBuilderView> createState() => _TeamBuilderViewState();
}

class _TeamBuilderViewState extends State<TeamBuilderView> {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final socketService = context.watch<BattleSocketService>();
    final profile = socketService.currentPlayer;

    // Load registered player teams if they exist, with no fallback list if empty
    final rawTeams = profile?['teams'] as List?;
    final List<Map<String, dynamic>> teams = rawTeams != null
        ? rawTeams.map((t) => Map<String, dynamic>.from(t as Map)).toList()
        : const [];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Constructor de equipos',
                      style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crea, edita y organiza tus equipos para la batalla.',
                      style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nuevo equipo'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: teams.isEmpty
                ? Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes equipos creados',
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Elige "Equipo Aleatorio" en la arena de batalla, o registra tus equipos personalizados para verlos aquí.',
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceMuted,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, c) {
                      final cross = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          childAspectRatio: 1.45,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: teams.length,
                        itemBuilder: (context, i) => _TeamCard(team: teams[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  const _TeamCard({required this.team});

  List<Color> _parseMonsterColors(dynamic value) {
    if (value is Color) return [value];
    if (value is String) {
      final types = value.split(',').map((t) => t.trim()).toList();
      if (types.isEmpty) return [AppColors.primary];

      if (types.length == 1) {
        return [PokemonTypeIcons.getColor(types[0])];
      } else {
        final c1 = PokemonTypeIcons.getColor(types[0]);
        final c2 = PokemonTypeIcons.getColor(types[1]);
        return [c1, c2];
      }
    }
    return [AppColors.primary];
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Safely extract monsters
    final rawMonsters = team['monsters'] as List?;
    final monsters = rawMonsters != null
        ? rawMonsters.map((m) => Map<String, dynamic>.from(m as Map)).toList()
        : const <Map<String, dynamic>>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.shield, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team['name'] ?? 'Equipo', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        team['description'] ?? '',
                        style: text.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 18)),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: monsters.map((m) {
                    final colorValue = m['color'];
                    final colors = _parseMonsterColors(colorValue);
                    final c1 = colors[0];
                    final c2 = colors.length > 1 ? colors[1] : c1;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            c1.withValues(alpha: 0.14),
                            c2.withValues(alpha: 0.14),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color.lerp(c1, c2, 0.5)!.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.catching_pokemon, color: c1, size: 14),
                          if (colors.length > 1) ...[
                            const SizedBox(width: 3),
                            Icon(Icons.catching_pokemon, color: c2, size: 14),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            m['name'] ?? 'Monstruo',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

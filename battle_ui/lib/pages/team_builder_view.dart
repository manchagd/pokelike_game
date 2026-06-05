import 'package:flutter/material.dart';
import '../theme.dart';

class TeamBuilderView extends StatefulWidget {
  const TeamBuilderView({super.key});

  @override
  State<TeamBuilderView> createState() => _TeamBuilderViewState();
}

class _TeamBuilderViewState extends State<TeamBuilderView> {
  final List<Map<String, dynamic>> _teams = [
    {
      'name': 'Equipo Lluvia',
      'description': 'Estrategia basada en clima de lluvia',
      'monsters': [
        {'name': 'Pelipper', 'color': Colors.blue},
        {'name': 'Swampert', 'color': Colors.blueAccent},
        {'name': 'Ferrothorn', 'color': Colors.green},
        {'name': 'Kingdra', 'color': Colors.cyan},
        {'name': 'Tornadus', 'color': Colors.purple},
        {'name': 'Zapdos', 'color': Colors.yellow},
      ],
    },
    {
      'name': 'Trick Room Core',
      'description': 'Controla la velocidad del campo',
      'monsters': [
        {'name': 'Cresselia', 'color': Colors.pinkAccent},
        {'name': 'Ursaluna', 'color': Colors.brown},
        {'name': 'Torkoal', 'color': Colors.deepOrange},
        {'name': 'Amoonguss', 'color': Colors.green},
        {'name': 'Hatterene', 'color': Colors.pink},
        {'name': 'Kingambit', 'color': Colors.grey},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
            child: LayoutBuilder(
              builder: (context, c) {
                final cross = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    childAspectRatio: 1.45,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: _teams.length,
                  itemBuilder: (context, i) => _TeamCard(team: _teams[i]),
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final monsters = team['monsters'] as List<Map<String, dynamic>>;

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
                      Text(team['name'], style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                    final color = m['color'] as Color;
                    return Chip(
                      avatar: Icon(Icons.catching_pokemon, color: color, size: 18),
                      label: Text(m['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: color.withValues(alpha: 0.12),
                      side: BorderSide(color: color.withValues(alpha: 0.4)),
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

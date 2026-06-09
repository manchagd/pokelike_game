import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../utils/pokemon_type_icons.dart';

class BattleView extends StatefulWidget {
  final String? battleCode;
  const BattleView({super.key, this.battleCode});

  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> {
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _feedbackScroll = ScrollController();
  final ScrollController _chatScroll = ScrollController();

  final List<String> _battleFeedback = [
    '¡Batalla iniciada!',
    'Esperando al oponente...',
  ];

  final List<Map<String, String>> _chatMessages = [
    {'sender': 'Oponente', 'message': '¡Buena suerte!'},
    {'sender': 'Tú', 'message': 'Igualmente, prepárate 😎'},
    {'sender': 'Oponente', 'message': 'Jaja veremos...'},
    {'sender': 'Tú', 'message': 'Mi Charizard te va a destruir'},
    {'sender': 'Oponente', 'message': 'Mi Gengar dice lo contrario'},
  ];

  final List<Map<String, dynamic>> _myMonsters = const [
    {'name': 'Charizard', 'hp': 78, 'maxHp': 100, 'level': 50},
    {'name': 'Blastoise', 'hp': 100, 'maxHp': 100, 'level': 48},
    {'name': 'Venusaur', 'hp': 45, 'maxHp': 95, 'level': 49},
    {'name': 'Pikachu', 'hp': 60, 'maxHp': 60, 'level': 45},
  ];

  final List<Map<String, dynamic>> _attacks = const [
    {'name': 'Lanzallamas', 'type': 'Fuego', 'power': 90},
    {'name': 'Vuelo', 'type': 'Volador', 'power': 90},
    {'name': 'Garra Dragón', 'type': 'Dragón', 'power': 80},
    {'name': 'Onda Ígnea', 'type': 'Fuego', 'power': 95},
  ];

  final Map<String, dynamic> _myActive = const {
    'name': 'Charizard',
    'hp': 78,
    'maxHp': 100,
    'level': 50,
  };
  final Map<String, dynamic> _oppActive = const {
    'name': 'Gengar',
    'hp': 92,
    'maxHp': 100,
    'level': 52,
  };

  @override
  void dispose() {
    _chatController.dispose();
    _chatFocusNode.dispose();
    _feedbackScroll.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final t = _chatController.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _chatMessages.add({'sender': 'Tú', 'message': t});
      _chatController.clear();
    });
    _chatFocusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            Text(
              'Combate en vivo',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          if (widget.battleCode != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Chip(
                avatar: const Icon(
                  Icons.tag,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  widget.battleCode!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth > 900 && c.maxHeight > 700;
            if (!isWide) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildParticipants(),
                    const SizedBox(height: 16),
                    _buildAttackPanel(),
                    const SizedBox(height: 16),
                    _buildLogPanel(height: 250),
                    const SizedBox(height: 16),
                    _buildMonstersPanel(),
                    const SizedBox(height: 16),
                    SizedBox(height: 360, child: _buildChatPanel()),
                  ],
                ),
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildParticipants(),
                      const SizedBox(height: 16),
                      _buildAttackPanel(),
                      const SizedBox(height: 16),
                      Expanded(child: _buildLogPanel()),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildMonstersPanel(),
                      const SizedBox(height: 16),
                      Expanded(child: _buildChatPanel()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticipants() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _ParticipantTile(
                label: 'TÚ',
                name: 'Entrenador Pro',
                color: AppColors.secondary,
                mon: _myActive,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(
              Icons.offline_bolt_outlined,
              color: AppColors.accent,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ParticipantTile(
                label: 'OPONENTE',
                name: 'Rival Master',
                color: AppColors.tertiary,
                mon: _oppActive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttackPanel() {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                const Icon(Icons.flash_on, color: AppColors.accent, size: 25),
                const SizedBox(width: 8),
                Text(
                  'Selecciona tu ataque',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                childAspectRatio: 4.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _attacks.length,
              itemBuilder: (context, i) {
                final a = _attacks[i];
                final c = PokemonTypeIcons.getColor(a['type']);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(c, AppColors.primaryA0, 0.35)!.withValues(alpha: 0.95),
                        c.withValues(alpha: 0.55),
                        AppColors.surfaceA0.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                    border: Border.all(
                      color: Color.lerp(c, AppColors.primaryA20, 0.3)!
                          .withValues(alpha: 0.75),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.45),
                        blurRadius: 16,
                        spreadRadius: -2,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: AppColors.primaryA0.withValues(alpha: 0.18),
                        blurRadius: 20,
                        spreadRadius: -4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap:
                          () => setState(
                            () => _battleFeedback.add('Usaste ${a['name']}!'),
                          ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.lerp(c, Colors.white, 0.2)!,
                                    c,
                                    Color.lerp(c, Colors.black, 0.35)!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.65),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: PokemonTypeIcons.buildSvgIcon(
                                a['type'],
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                '${a['power']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogPanel({double? height}) {
    final text = Theme.of(context).textTheme;
    final body = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Registro de combate',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: ListView.builder(
                controller: _feedbackScroll,
                itemCount: _battleFeedback.length,
                itemBuilder:
                    (context, i) => Padding(
                      padding: EdgeInsets.only(
                        left: 0,
                        top: 3,
                        right: 0,
                        bottom: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '›',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _battleFeedback[i],
                              style: text.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
    final card = Card(child: body);
    return height != null ? SizedBox(height: height, child: card) : card;
  }

  Widget _buildMonstersPanel() {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.catching_pokemon,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tu equipo',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.0,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _myMonsters.length,
              itemBuilder: (context, i) {
                final m = _myMonsters[i];
                final pct = (m['hp'] as int) / (m['maxHp'] as int);
                Color hpColor = AppColors.success;
                if (pct < 0.5) hpColor = AppColors.accent;
                if (pct < 0.25) hpColor = AppColors.danger;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(hpColor, AppColors.primaryA0, 0.4)!
                            .withValues(alpha: 0.85),
                        hpColor.withValues(alpha: 0.4),
                        AppColors.surfaceA0.withValues(alpha: 0.9),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                    border: Border.all(
                      color: Color.lerp(hpColor, AppColors.primaryA20, 0.35)!
                          .withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: hpColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: -2,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: AppColors.primaryA0.withValues(alpha: 0.15),
                        blurRadius: 18,
                        spreadRadius: -4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap:
                          () => setState(
                            () => _battleFeedback.add(
                              '¡Cambiaste a ${m['name']}!',
                            ),
                          ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.catching_pokemon,
                              color: hpColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    m['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Nv.${m['level']} • HP ${m['hp']}/${m['maxHp']}',
                                    style: const TextStyle(
                                      color: AppColors.onSurfaceMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 4,
                                      backgroundColor: AppColors.surfaceHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        hpColor,
                                      ),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chat',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: ListView.builder(
                  controller: _chatScroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, i) {
                    final m = _chatMessages[i];
                    final isMe = m['sender'] == 'Tú';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment:
                            isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? AppColors.primary.withValues(
                                          alpha: 0.18,
                                        )
                                        : AppColors.surfaceHigh,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isMe ? 12 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 12),
                                ),
                                border: Border.all(
                                  color:
                                      isMe
                                          ? AppColors.primary.withValues(
                                            alpha: 0.35,
                                          )
                                          : AppColors.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    m['sender']!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          isMe
                                              ? AppColors.primary
                                              : AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(m['message']!, style: text.bodyMedium),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    focusNode: _chatFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final String label;
  final String name;
  final Color color;
  final Map<String, dynamic> mon;
  const _ParticipantTile({
    required this.label,
    required this.name,
    required this.color,
    required this.mon,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pct = (mon['hp'] as int) / (mon['maxHp'] as int);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.catching_pokemon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                mon['name'],
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                'Nv.${mon['level']}',
                style: const TextStyle(
                  color: AppColors.onSurfaceMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'HP ${mon['hp']}/${mon['maxHp']}',
            style: const TextStyle(
              color: AppColors.onSurfaceMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

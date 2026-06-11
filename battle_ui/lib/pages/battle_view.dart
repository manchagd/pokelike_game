import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../utils/pokemon_type_icons.dart';
import '../utils/battle_socket_service.dart';

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

  StreamSubscription? _battleSub;
  StreamSubscription? _chatSub;
  late BattleSocketService _socketService;

  final List<String> _battleFeedback = [];
  final List<Map<String, String>> _chatMessages = [];

  List<Map<String, dynamic>> _myMonsters = [];
  List<Map<String, dynamic>> _attacks = [];
  Map<String, dynamic> _myActive = {};
  Map<String, dynamic> _oppActive = {};

  int _turn = 1;
  String _phase = 'waiting_actions';
  String _myName = 'Tú';
  String _oppName = 'Oponente';
  int? _turnExpiresAt;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();

    _turn = 1;
    _phase = 'waiting_actions';

    _battleFeedback.addAll([
      '¡Batalla iniciada!',
      'Esperando al oponente...',
    ]);

    _chatMessages.add({
      'sender': 'Sistema',
      'message': 'Te has unido al chat del combate.',
    });

    _myMonsters = [
      {'name': 'Charizard', 'hp': 78, 'maxHp': 100, 'level': 50},
      {'name': 'Blastoise', 'hp': 100, 'maxHp': 100, 'level': 48},
      {'name': 'Venusaur', 'hp': 45, 'maxHp': 95, 'level': 49},
      {'name': 'Pikachu', 'hp': 60, 'maxHp': 60, 'level': 45},
    ];

    _attacks = [
      {'name': 'Lanzallamas', 'type': 'Fuego', 'power': 90},
      {'name': 'Vuelo', 'type': 'Volador', 'power': 90},
      {'name': 'Garra Dragón', 'type': 'Dragón', 'power': 80},
      {'name': 'Onda Ígnea', 'type': 'Fuego', 'power': 95},
    ];

    _myActive = {
      'name': 'Charizard',
      'hp': 78,
      'maxHp': 100,
      'level': 50,
    };

    _oppActive = {
      'name': 'Gengar',
      'hp': 92,
      'maxHp': 100,
      'level': 52,
    };

    _socketService = context.read<BattleSocketService>();
    if (widget.battleCode != null) {
      _socketService.connectToBattle(widget.battleCode!);
    }

    _battleSub = _socketService.battleEvents.listen(_handleBattleEvent);
    _chatSub = _socketService.chatEvents.listen(_handleChatMessage);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _battleSub?.cancel();
    _chatSub?.cancel();
    _socketService.leaveBattle();

    _chatController.dispose();
    _chatFocusNode.dispose();
    _feedbackScroll.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _handleChatMessage(Map<String, dynamic> msg) {
    final senderId = msg['player_id']?.toString();
    final username = msg['username'] as String? ?? 'Anonymous';
    final body = msg['body'] as String? ?? '';

    final socketService = _socketService;
    final meId = socketService.currentPlayer?['id']?.toString();
    final isMe = senderId != null && senderId == meId;

    setState(() {
      _chatMessages.add({
        'sender': isMe ? 'Tú' : username,
        'message': body,
      });
    });

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

  void _handleBattleEvent(Map<String, dynamic> data) {
    final eventName = data['event'] as String?;
    final eventPayload = data['payload'] as Map<String, dynamic>? ?? {};

    if (eventName == 'battle_timeout') {
      final reason = eventPayload['reason'] as String? ?? 'Se ha agotado el tiempo de gracia de 2 minutos.';
      _showTimeoutDialog(reason);
      return;
    }

    if (eventName == 'battle_state') {
      final myId = _socketService.currentPlayer?['id']?.toString();
      final activeA = eventPayload['active_monster_a'];
      final activeB = eventPayload['active_monster_b'];
      final newTurn = eventPayload['turn'] as int? ?? 1;
      final newPhase = eventPayload['phase'] as String? ?? 'waiting_actions';
      final newExpiresAt = eventPayload['turn_expires_at'] as int?;

      final playerAName = eventPayload['player_a_name'] as String? ?? 'Entrenador A';
      final playerBName = eventPayload['player_b_name'] as String? ?? 'Entrenador B';

      String myName = 'Tú';
      String oppName = 'Oponente';

      Map<String, dynamic>? myActiveEvent;
      Map<String, dynamic>? oppActiveEvent;

      if (activeA != null && activeA['owner_id']?.toString() == myId) {
        myName = "$playerAName (Tú)";
        oppName = playerBName;
        myActiveEvent = activeA;
        oppActiveEvent = activeB;
      } else if (activeB != null && activeB['owner_id']?.toString() == myId) {
        myName = "$playerBName (Tú)";
        oppName = playerAName;
        myActiveEvent = activeB;
        oppActiveEvent = activeA;
      } else {
        myName = playerAName;
        oppName = playerBName;
        myActiveEvent = activeA;
        oppActiveEvent = activeB;
      }

      setState(() {
        _turn = newTurn;
        _phase = newPhase;
        _myName = myName;
        _oppName = oppName;
        _turnExpiresAt = newExpiresAt;
        if (myActiveEvent != null) {
          _myActive = {
            'name': myActiveEvent['name'] ?? '?',
            'hp': myActiveEvent['hp'] ?? 0,
            'maxHp': myActiveEvent['max_hp'] ?? 100,
            'level': myActiveEvent['level'] ?? 50,
          };
        }
        if (oppActiveEvent != null) {
          _oppActive = {
            'name': oppActiveEvent['name'] ?? '?',
            'hp': oppActiveEvent['hp'] ?? 0,
            'maxHp': oppActiveEvent['max_hp'] ?? 100,
            'level': oppActiveEvent['level'] ?? 50,
          };
        }

        final logs = eventPayload['log'] as List?;
        if (logs != null) {
          for (var l in logs) {
            final logStr = l.toString();
            if (!_battleFeedback.contains(logStr)) {
              _battleFeedback.add(logStr);
            }
          }
        }
      });
      _startLocalCountdown();
      _scrollToFeedbackBottom();
    } else {
      setState(() {
        _battleFeedback.add('Evento recibido: $eventName');
      });
      _scrollToFeedbackBottom();
    }
  }

  void _scrollToFeedbackBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_feedbackScroll.hasClients) {
        _feedbackScroll.animateTo(
          _feedbackScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startLocalCountdown() {
    _countdownTimer?.cancel();
    if (_turnExpiresAt == null) return;

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final diffMs = _turnExpiresAt! - nowMs;
    _remainingSeconds = (diffMs / 1000).round();

    if (_remainingSeconds <= 0) {
      setState(() {
        _remainingSeconds = 0;
      });
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = remainingSeconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  void _showTimeoutDialog(String reason) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.accent),
              SizedBox(width: 10),
              Text('Combate finalizado'),
            ],
          ),
          content: Text(reason),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  context.pop();
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage() {
    final t = _chatController.text.trim();
    if (t.isEmpty) return;
    _socketService.sendChatMessage(t);
    _chatController.clear();
    _chatFocusNode.requestFocus();
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
        child: Column(
          children: [
            _buildTopTurnBanner(text),
            const SizedBox(height: 16),
            Expanded(
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
          ],
        ),
      ),
    );
  }

  Widget _buildParticipants() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: _ParticipantTile(
                label: 'TÚ',
                name: _myName,
                color: AppColors.secondary,
                mon: _myActive,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.offline_bolt_outlined,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ParticipantTile(
                label: 'OPONENTE',
                name: _oppName,
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
                      onTap: () {
                        setState(() {
                          _battleFeedback.add('Enviando acción: Usar ${a['name']}...');
                        });
                        _scrollToFeedbackBottom();
                        _socketService.sendAction('attack', {
                          'move_id': a['name'].toString().toLowerCase(),
                          'target_id': _oppActive['name']?.toString().toLowerCase(),
                        });
                      },
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
                      onTap: () {
                        setState(() {
                          _battleFeedback.add('Enviando acción: Cambiar a ${m['name']}...');
                        });
                        _scrollToFeedbackBottom();
                        _socketService.sendAction('switch', {
                          'monster_id': m['name'].toString().toLowerCase(),
                        });
                      },
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

  Widget _buildTopTurnBanner(TextTheme text) {
    final isWaiting = _phase == 'waiting_actions';
    final statusColor = isWaiting ? AppColors.accent : AppColors.success;
    final statusText = isWaiting ? 'Esperando acciones...' : 'Procesando turno...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceA0.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Turno $_turn',
            style: text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 14,
            width: 1,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(width: 12),
          if (isWaiting)
            const _PulsingIndicator(color: AppColors.accent)
          else
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: text.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (isWaiting && _remainingSeconds > 0) ...[
            const Icon(
              Icons.timer_outlined,
              color: AppColors.onSurfaceMuted,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(_remainingSeconds),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ],
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
    final pct = (mon['hp'] as num?) != null && (mon['maxHp'] as num?) != null && (mon['maxHp'] as num) > 0
        ? (mon['hp'] as num) / (mon['maxHp'] as num)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Nv.${mon['level'] ?? 50}',
                style: text.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.catching_pokemon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                mon['name'] ?? '?',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${mon['hp'] ?? 0}/${mon['maxHp'] ?? 100}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingIndicator extends StatefulWidget {
  final Color color;
  const _PulsingIndicator({required this.color});

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.6),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import '../nav.dart';
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

  // Audio state
  static const double _bgmVolumeScale = 0.5; // Límite máximo de volumen real (0.5 = 50%, 0.3 = 30%)
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _volume = 0.3;
  bool _isMuted = false;
  bool _isMusicPlaying = false;
  String? _currentTrack;

  static const List<String> _battleMusicTracks = [
    'bw-rival.mp3',
    'bw-subway-trainer.mp3',
    'bw-trainer.mp3',
    'bw2-homika-dogars.mp3',
    'bw2-kanto-gym-leader.mp3',
    'bw2-rival.mp3',
    'dpp-rival.mp3',
    'dpp-trainer.mp3',
    'hgss-johto-trainer.mp3',
    'hgss-kanto-trainer.mp3',
    'oras-rival.mp3',
    'oras-trainer.mp3',
    'sm-rival.mp3',
    'sm-trainer.mp3',
    'spl-elite4.mp3',
    'xy-rival.mp3',
    'xy-trainer.mp3',
  ];

  final List<String> _battleFeedback = [];
  final List<Map<String, String>> _chatMessages = [];

  List<Map<String, dynamic>> _myMonsters = [];
  Map<String, dynamic> _myActive = {};
  Map<String, dynamic> _oppActive = {};
  int _myAliveCount = 0;
  int _oppAliveCount = 0;

  int _turn = 1;
  BattlePhase _phase = BattlePhase.syncing;
  String _myName = 'Tú';
  String _oppName = 'Oponente';
  int? _turnExpiresAt;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  String _battleFormat = '1v1';
  int _expectedPlayers = 2;
  int _connectedPlayers = 0;
  int? _selectedLeadId;
  bool _leadSubmitted = false;
  String? _submittedActionType;
  dynamic _submittedActionTargetId;
  dynamic _submittedActionSwitchTargetId;
  bool _pendingEnforceSwitch = false;
  Map<String, dynamic>? _pendingAttack;

  String? _errorMessage;
  Timer? _syncTimeoutTimer;

  void _startSyncTimeoutTimer() {
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _phase == BattlePhase.syncing) {
        setState(() {
          _phase = BattlePhase.error;
          _errorMessage = 'Se ha agotado el tiempo de espera para conectar con el servidor de combate. Por favor, verifica tu conexión o el estado del servidor.';
        });
      }
    });
  }

  void _cancelSyncTimeoutTimer() {
    _syncTimeoutTimer?.cancel();
    _syncTimeoutTimer = null;
  }

  @override
  void initState() {
    super.initState();
    _loadAudioSettings();

    _turn = 1;
    _phase = BattlePhase.syncing;
    _errorMessage = null;
    _startSyncTimeoutTimer();
    _battleFormat = '1v1';
    _expectedPlayers = 2;
    _connectedPlayers = 0;
    _selectedLeadId = null;
    _leadSubmitted = false;
    _submittedActionType = null;
    _submittedActionTargetId = null;
    _submittedActionSwitchTargetId = null;

    _battleFeedback.addAll([
      '¡Batalla iniciada!',
      'Esperando al oponente...',
    ]);

    _chatMessages.add({
      'sender': 'Sistema',
      'message': 'Te has unido al chat del combate.',
    });

    _myMonsters = [];
    _myActive   = {};
    _oppActive  = {};


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
    _syncTimeoutTimer?.cancel();
    _battleSub?.cancel();
    _chatSub?.cancel();
    _socketService.leaveBattle();

    _chatController.dispose();
    _chatFocusNode.dispose();
    _feedbackScroll.dispose();
    _chatScroll.dispose();

    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Audio helper methods
  bool _isInProgress(BattlePhase phase) {
    return phase == BattlePhase.waitingActions ||
        phase == BattlePhase.resolving;
  }

  Future<void> _loadAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _volume = prefs.getDouble('bgm_volume') ?? 0.3;
        _isMuted = prefs.getBool('bgm_muted') ?? false;
      });
      await _audioPlayer.setVolume(_isMuted ? 0.0 : (_volume * _bgmVolumeScale));
    } catch (e) {
      debugPrint("Error loading audio preferences: $e");
    }
  }

  Future<void> _saveAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('bgm_volume', _volume);
      await prefs.setBool('bgm_muted', _isMuted);
    } catch (e) {
      debugPrint("Error saving audio preferences: $e");
    }
  }

  Future<void> _startBattleMusic() async {
    if (_isMusicPlaying) return;

    final random = math.Random();
    final index = random.nextInt(_battleMusicTracks.length);
    final track = _battleMusicTracks[index];
    _currentTrack = track;
    _isMusicPlaying = true;

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_isMuted ? 0.0 : (_volume * _bgmVolumeScale));
      await _audioPlayer.play(UrlSource('https://play.pokemonshowdown.com/audio/$track'));
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error playing battle music ($track): $e");
      _isMusicPlaying = false;
    }
  }

  Future<void> _stopBattleMusic() async {
    if (!_isMusicPlaying) return;
    _isMusicPlaying = false;
    _currentTrack = null;
    try {
      await _audioPlayer.stop();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error stopping battle music: $e");
    }
  }


  Future<void> _updateVolume(double val) async {
    setState(() {
      _volume = val;
      if (_volume > 0.0) {
        _isMuted = false;
      }
    });
    try {
      await _audioPlayer.setVolume(_isMuted ? 0.0 : (_volume * _bgmVolumeScale));
      if (!_isMusicPlaying && _isInProgress(_phase) && !_isMuted && _volume > 0.0) {
        _startBattleMusic();
      }
    } catch (e) {
      debugPrint("Error updating volume: $e");
    }
    _saveAudioSettings();
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    try {
      await _audioPlayer.setVolume(_isMuted ? 0.0 : (_volume * _bgmVolumeScale));
      if (!_isMusicPlaying && !_isMuted && _isInProgress(_phase)) {
        _startBattleMusic();
      }
    } catch (e) {
      debugPrint("Error toggling mute: $e");
    }
    _saveAudioSettings();
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

    if (eventName == 'connection_error') {
      _cancelSyncTimeoutTimer();
      _stopBattleMusic();
      setState(() {
        _phase = BattlePhase.error;
        _errorMessage = eventPayload['reason'] as String? ?? 'Error al conectar al canal de combate.';
      });
      return;
    }

    if (eventName == 'setup_pokemons') {
      _cancelSyncTimeoutTimer();
      final pokemons = eventPayload['pokemons'] as List?;
      if (pokemons != null) {
        setState(() {
          _myMonsters = pokemons.map((p) {
            final map = Map<String, dynamic>.from(p as Map);
            map['maxHp']   = map['max_hp']  ?? map['maxHp']  ?? 100;
            map['level']   = map['level']   ?? 50;
            map['lead']    = map['lead']    ?? false;
            map['attacks'] = map['attacks'] ?? [];
            map['sprite_url'] = map['sprite_url'] ?? map['spriteUrl'];
            return map;
          }).toList();
        });
      }
      return;
    }

    if (eventName == 'battle_timeout') {
      final reason = eventPayload['reason'] as String? ?? 'Se ha agotado el tiempo de gracia de 2 minutos.';
      _stopBattleMusic();
      _showTimeoutDialog(reason);
      return;
    }

    if (eventName == 'battle_ended') {
      final reason = eventPayload['reason'] as String? ?? 'El combate ha finalizado.';
      _stopBattleMusic();
      _showBattleEndedDialog(reason);
      return;
    }

    if (eventName == 'battle_state') {
      _cancelSyncTimeoutTimer();
      final myId = _socketService.currentPlayer?['id']?.toString() ??
          _socketService.currentPlayer?['name']?.toString() ??
          '';

      final newTurn = eventPayload['turn'] as int? ?? 1;
      final newPhaseStr = eventPayload['phase'] as String?;
      final newPhase = BattlePhase.fromString(newPhaseStr);
      final newExpiresAt = eventPayload['turn_expires_at'] as int?;
      final format = eventPayload['battle_format'] as String? ?? '1v1';
      final expected = eventPayload['expected_players'] as int? ?? 2;
      final connected = eventPayload['connected_players'] as int? ?? 0;

      final players = eventPayload['players'] as List? ?? [];

      Map<String, dynamic>? myPlayer;
      Map<String, dynamic>? oppPlayer;

      for (final p in players) {
        if (p['id']?.toString() == myId || p['name'] == _socketService.currentPlayer?['name']) {
          myPlayer = p as Map<String, dynamic>;
        } else {
          oppPlayer = p as Map<String, dynamic>;
        }
      }

      String myName = myPlayer?['name'] != null ? "${myPlayer!['name']} (Tú)" : 'Tú';
      String oppName = oppPlayer?['name'] ?? 'Oponente';

      setState(() {
        if (_turn != newTurn || (newPhase != _phase && newPhase == BattlePhase.waitingActions)) {
          _submittedActionType = null;
          _submittedActionTargetId = null;
          _submittedActionSwitchTargetId = null;
        }

        _turn = newTurn;
        if (newPhase != _phase) {
          if (newPhase == BattlePhase.settingUp) {
            _selectedLeadId = null;
            _leadSubmitted = false;
          }
          _phase = newPhase;
        }
        _myName = myName;
        _oppName = oppName;
        _turnExpiresAt = newExpiresAt;
        _battleFormat = format;
        _expectedPlayers = expected;
        _connectedPlayers = connected;

        if (myPlayer != null) {
          _myAliveCount = myPlayer['alive_pokemon_count'] as int? ?? 0;
          final am = myPlayer['active_monster'] as Map<String, dynamic>?;
          if (am != null && am.isNotEmpty) {
            _myActive = {
              'id': am['id'],
              'field_position': am['field_position'] as Map<String, dynamic>?,
              'name': am['name'] ?? '?',
              'hp': am['hp'] ?? 0,
              'maxHp': am['max_hp'] ?? 100,
              'level': am['level'] ?? 50,
              'sprite_url': am['sprite_url'] ?? am['spriteUrl'],
              'status': am['status'] ?? 'normal',
            };
          } else {
            _myActive = {};
          }
        }

        if (oppPlayer != null) {
          _oppAliveCount = oppPlayer['alive_pokemon_count'] as int? ?? 0;
          final am = oppPlayer['active_monster'] as Map<String, dynamic>?;
          if (am != null && am.isNotEmpty) {
            _oppActive = {
              'id': am['id'],
              'field_position': am['field_position'] as Map<String, dynamic>?,
              'name': am['name'] ?? '?',
              'hp': am['hp'] ?? 0,
              'maxHp': am['max_hp'] ?? 100,
              'level': am['level'] ?? 50,
              'sprite_url': am['sprite_url'] ?? am['spriteUrl'],
              'status': am['status'] ?? 'normal',
            };
          } else {
            _oppActive = {};
          }
        }

        final logs = eventPayload['log'] as List?;
        if (logs != null) {
          _battleFeedback.clear();
          _battleFeedback.addAll(logs.map((l) => l.toString()));
        }
      });

      if (_isInProgress(newPhase)) {
        _startBattleMusic();
      } else if (newPhase == BattlePhase.finished || newPhase == BattlePhase.error) {
        _stopBattleMusic();
      }

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

  String _findAttackName(dynamic id) {
    if (id == null) return '';
    final lead = _myMonsters.where((m) => m['lead'] == true).firstOrNull;
    final attacks = (lead?['attacks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final attack = attacks.where((a) => a['id'] == id).firstOrNull;
    return attack?['name'] as String? ?? '';
  }

  String _findMonsterName(dynamic id) {
    if (id == null) return '';
    final mon = _myMonsters.where((m) => m['id'] == id).firstOrNull;
    return mon?['name'] as String? ?? '';
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
          title: Row(
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
                  context.go(AppRoutes.home);
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _showBattleEndedDialog(String reason) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.sports_kabaddi_rounded, color: AppColors.primary),
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
                  context.go(AppRoutes.home);
                }
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        );
      },
    );
  }

  void _showSurrenderConfirmation() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.outlined_flag_rounded, color: AppColors.danger),
              SizedBox(width: 10),
              Text('¿Rendirse?'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas rendirte? Esto finalizará el combate y registrará tu derrota.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _socketService.sendAction('forfeit', {});
              },
              child: const Text('Rendirse'),
            ),
          ],
        );
      },
    );
  }

  void _submitAttackSwitch(int switchedInSnapshotId) {
    final attack = _pendingAttack!;
    final oppPosition = _oppActive['field_position'] as Map<String, dynamic>?;
    final targetStr = oppPosition != null
        ? '${oppPosition['side']}${oppPosition['group']}'
        : 'B1';

    setState(() {
      _pendingEnforceSwitch = false;
      _pendingAttack = null;
      _submittedActionType = 'attack_switch';
      _submittedActionTargetId = attack['id'];
      _submittedActionSwitchTargetId = switchedInSnapshotId;
      _battleFeedback.add('Enviando acción: ${attack['name']} + cambio de Pokémon...');
    });
    _scrollToFeedbackBottom();

    _socketService.sendAction('attack_switch', {
      'attack_id': attack['id'],
      'pokemon_id': _myActive['id'] as int,
      'targets': [targetStr],
      'pokemon_switched_id': switchedInSnapshotId,
    });
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
    final isBattleConnected = context.watch<BattleSocketService>().isBattleConnected;
    final showWarning = !isBattleConnected && _phase != BattlePhase.finished;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Row(
          children: [
            _buildCompactTopTurnBanner(text),
            if (!_phase.isWaitingPlayers) ...[
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _myName.replaceAll(' (Tú)', ''),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          _oppName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
        actions: [
          if (!_phase.isWaitingPlayers)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _showSurrenderConfirmation,
                icon: Icon(Icons.flag_rounded, color: AppColors.danger, size: 18),
                label: Text(
                  'Rendirse',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<double>(
              icon: Icon(
                _isMuted
                    ? Icons.volume_off_rounded
                    : (_volume == 0
                        ? Icons.volume_mute_rounded
                        : (_volume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded)),
                color: _isMuted ? AppColors.onSurfaceMuted : AppColors.primary,
              ),
              tooltip: 'Control de volumen BGM',
              offset: const Offset(0, 40),
              itemBuilder: (context) => [
                PopupMenuItem<double>(
                  enabled: false,
                  child: StatefulBuilder(
                    builder: (context, setPopupState) {
                      return SizedBox(
                        width: 220,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Volumen BGM',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: () {
                                    _toggleMute();
                                    setPopupState(() {});
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.volume_down_rounded, size: 16),
                                Expanded(
                                  child: Slider(
                                    value: _isMuted ? 0.0 : _volume,
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: AppColors.primary,
                                    inactiveColor: AppColors.outline,
                                    onChanged: (val) {
                                      _updateVolume(val);
                                      setPopupState(() {});
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const Icon(Icons.volume_up_rounded, size: 16),
                              ],
                            ),
                            if (_currentTrack != null) ...[
                              const Divider(),
                              Text(
                                'Reproduciendo:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentTrack!.replaceAll('.mp3', '').toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else ...[
                              const Divider(),
                              Text(
                                'Música silenciada o detenida',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (widget.battleCode != null)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.battleCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Código ${widget.battleCode!} copiado al portapapeles'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Chip(
                    avatar: Icon(
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
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final isWide = c.maxWidth > 900 && c.maxHeight > 700;
                      final isSyncing = _phase.isSyncing;
                      final isError = _phase.isError;
                      final isWaitingPlayers = _phase.isWaitingPlayers;
                      final isSettingUp = _phase.isSettingUp;

                      if (isSyncing) {
                        return _buildSyncingPanel();
                      }

                      if (isError) {
                        return _buildErrorPanel();
                      }

                      if (isWaitingPlayers) {
                        if (!isWide) {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildWaitingRoomPanel(),
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
                              child: _buildWaitingRoomPanel(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _buildChatPanel(),
                            ),
                          ],
                        );
                      }

                      if (isSettingUp) {
                        if (!isWide) {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildLeadSelectionPanel(),
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
                              child: _buildLeadSelectionPanel(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _buildChatPanel(),
                            ),
                          ],
                        );
                      }

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
          if (showWarning)
            Positioned(
              top: 12,
              left: 24,
              right: 24,
              child: _buildNoConnectionBanner(text),
            ),
        ],
      ),
    );
  }

  Widget _buildNoConnectionBanner(TextTheme text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _PulsingIcon(
                icon: Icons.wifi_off_rounded,
                color: AppColors.danger,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Conexión perdida',
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Intentando reconectar al combate...',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.danger),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncingPanel() {
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceHigh.withValues(alpha: 0.95),
              AppColors.surface.withValues(alpha: 0.98),
            ],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Estableciendo Sincronización',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Obteniendo el estado del combate desde el servidor...',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Volver al Inicio'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPanel() {
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: AppColors.danger.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceHigh.withValues(alpha: 0.95),
              AppColors.surface.withValues(alpha: 0.98),
            ],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.danger,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Error de Sincronización',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage ?? 'Ocurrió un error inesperado al intentar cargar el combate.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Inicio'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _phase = BattlePhase.syncing;
                        _errorMessage = null;
                      });
                      _startSyncTimeoutTimer();
                      _socketService.connectToBattle(widget.battleCode!);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
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

  Widget _buildWaitingRoomPanel() {
    final text = Theme.of(context).textTheme;

    // We want to list players
    // Player 1 (us or player A)
    // Player 2 (player B or opponent)
    final player1Connected = _connectedPlayers >= 1;
    final player2Connected = _connectedPlayers >= 2;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceHigh.withValues(alpha: 0.95),
              AppColors.surface.withValues(alpha: 0.98),
            ],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.people_alt_rounded,
                color: AppColors.accent,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // Title and Subtitle
            Text(
              'Lobby de Combate',
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esperando entrenadores para iniciar el combate...',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 28),

            // Format and progress badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'Formato: $_battleFormat • Conectados: $_connectedPlayers / $_expectedPlayers',
                style: text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Player list
            Column(
              children: [
                _buildLobbyPlayerTile(
                  name: player1Connected ? _myName : 'Buscando Entrenador...',
                  isConnected: player1Connected,
                  role: 'Jugador 1',
                  isMe: player1Connected && _myName.contains('(Tú)'),
                ),
                const SizedBox(height: 12),
                _buildLobbyPlayerTile(
                  name: player2Connected ? _oppName : 'Esperando Oponente...',
                  isConnected: player2Connected,
                  role: 'Jugador 2',
                  isMe: player2Connected && _oppName.contains('(Tú)'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            // Tips banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.onSurfaceMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El combate comenzará automáticamente cuando se complete el cupo.',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadSelectionPanel() {
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceHigh.withValues(alpha: 0.95),
              AppColors.surface.withValues(alpha: 0.98),
            ],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.catching_pokemon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECCIÓN DE LÍDER',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Elige el Pokémon con el que iniciarás el combate.',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Grid
            Expanded(
              child: _myMonsters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando tus Pokémon...',
                            style: TextStyle(color: AppColors.onSurfaceMuted),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      itemCount: _myMonsters.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, i) {
                        final m = _myMonsters[i];
                        final id = m['id'] as int;
                        final name = m['name'] as String? ?? 'Pokémon';
                        final hp = m['hp'] as int? ?? 100;
                        final maxHp = m['maxHp'] as int? ?? 100;
                        final level = m['level'] as int? ?? 50;
                        final types = (m['types'] as List?)?.cast<String>() ?? [];
                        final isSelected = _selectedLeadId == id;
                        final pct = hp / maxHp;

                        Color hpColor = AppColors.success;
                        if (pct < 0.5) hpColor = AppColors.accent;
                        if (pct < 0.25) hpColor = AppColors.danger;

                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (AppColors.isDark
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : const Color(0xFFEDE7F6))
                                : AppColors.surfaceHighest,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.outlineVariant.withValues(alpha: 0.4),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                    )
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              onTap: _leadSubmitted
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedLeadId = id;
                                      });
                                    },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 13,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      'Nv. $level • HP $hp/$maxHp',
                                                      style: TextStyle(
                                                        color: AppColors.onSurfaceMuted,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.primary,
                                                  size: 18,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          // Types row
                                          Row(
                                            children: types.map((t) {
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 4),
                                                child: PokemonTypeIcons.buildTypeBadge(t, fontSize: 8),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(height: 3),
                                          // HP bar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              minHeight: 3.5,
                                              backgroundColor: AppColors.surface,
                                              valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (m['sprite_url'] != null && (m['sprite_url'] as String).isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Image.network(
                                        m['sprite_url'] as String,
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // Footer / Button
            if (_leadSubmitted)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Esperando a que el oponente elija su líder...',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              FilledButton(
                onPressed: _selectedLeadId == null
                    ? null
                    : () {
                        _socketService.sendAction('select_lead', {'lead': _selectedLeadId});
                        setState(() {
                          _leadSubmitted = true;
                        });
                      },
                child: const Text('Confirmar Líder'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyPlayerTile({
    required String name,
    required bool isConnected,
    required String role,
    required bool isMe,
  }) {
    final text = Theme.of(context).textTheme;
    final dotColor = isConnected ? AppColors.success : AppColors.onSurfaceMuted.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.surface.withValues(alpha: 0.4)
            : AppColors.background.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isConnected
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Connection status dot/indicator
          if (isConnected)
            _PulsingIndicator(color: AppColors.success)
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 14),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: isConnected ? FontWeight.w800 : FontWeight.w500,
                    color: isConnected ? AppColors.onSurface : AppColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role + (isMe ? ' (Tú)' : ''),
                  style: text.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.secondary : AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),

          // Right status label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.background.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              isConnected ? 'Listo' : 'Pendiente',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isConnected ? AppColors.success : AppColors.onSurfaceMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokeballs(int aliveCount, Color color, bool alignRight) {
    final isDark = AppColors.isDark;
    // Use AppColors.primary for active pokeballs so both sides have symmetric brightness
    final Color activeColor = AppColors.primary;
    // High contrast solid fainted colors (dark grey in dark mode, light grey in light mode)
    final Color faintedColor = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFCCCCCC);

    return Row(
      mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Icon(
            Icons.catching_pokemon,
            size: 11,
            color: index < aliveCount ? activeColor : faintedColor,
          ),
        );
      }),
    );
  }

  Widget _buildParticipants() {
    // The active mon IS the lead — just check if any lead exists
    final myIsLead = _myMonsters.any((m) => m['lead'] == true);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Pokeballs row aligned with cards
            Row(
              children: [
                Expanded(
                  child: _buildPokeballs(_myAliveCount, AppColors.secondary, false),
                ),
                const SizedBox(width: 46), // Middle gap matching VS container width + horizontal gaps
                Expanded(
                  child: _buildPokeballs(_oppAliveCount, AppColors.tertiary, true),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Row 2: Cards and clashing swords VS indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _ParticipantTile(
                    label: 'TÚ',
                    name: _myName,
                    color: AppColors.secondary,
                    mon: _myActive,
                    isLead: myIsLead,
                    aliveCount: _myAliveCount,
                    mirror: false,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: SvgPicture.string(
                    _crossedSwordsSvg,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ParticipantTile(
                    label: 'OPONENTE',
                    name: _oppName,
                    color: AppColors.tertiary,
                    mon: _oppActive,
                    isLead: false, // opp lead not exposed
                    aliveCount: _oppAliveCount,
                    mirror: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttackPanel() {
    final text = Theme.of(context).textTheme;

    // Pull attacks from the lead Pokémon
    final lead = _myMonsters.where((m) => m['lead'] == true).firstOrNull;
    final attacks = (lead?['attacks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final bool isActionSubmitted = _submittedActionType == 'attack' || _submittedActionType == 'attack_switch';
    final bool isPendingEnforce = _pendingEnforceSwitch && _pendingAttack != null;
    final bool isAnyAttackSelected = isActionSubmitted || isPendingEnforce;
    final int? selectedAttackId = isActionSubmitted
        ? _submittedActionTargetId
        : (isPendingEnforce ? _pendingAttack!['id'] as int? : null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Movimientos',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                if (isAnyAttackSelected) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActionSubmitted
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isActionSubmitted
                            ? AppColors.success.withValues(alpha: 0.35)
                            : AppColors.info.withValues(alpha: 0.35),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isActionSubmitted ? AppColors.success : AppColors.info,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActionSubmitted
                              ? 'ENVIADO: ${_findAttackName(selectedAttackId).toUpperCase()}'
                              : 'SELECCIONADO: ${_findAttackName(selectedAttackId).toUpperCase()}',
                          style: TextStyle(
                            color: isActionSubmitted ? AppColors.success : AppColors.info,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (attacks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Elige tu Pokémon líder para ver sus movimientos.',
                    style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Row(
                children: List.generate(attacks.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < attacks.length - 1 ? 6.0 : 0.0,
                      ),
                      child: _buildAttackCard(
                        attacks[index],
                        isDimmed: isAnyAttackSelected && selectedAttackId != attacks[index]['id'],
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttackCard(Map<String, dynamic> attack, {bool isDimmed = false}) {
    final types = (attack['types'] as List?)?.cast<String>() ?? [];
    final name     = attack['name']     as String? ?? '—';
    final power    = attack['power']    as int?;
    final pp       = attack['pp']       as int?;
    final accuracy = attack['accuracy'] as int?;
    final category = attack['category'] as String? ?? 'Physical';

    final accentColor = types.isNotEmpty
        ? PokemonTypeIcons.getColor(types.first)
        : AppColors.outlineVariant;

    final isSelected = ((_submittedActionType == 'attack' || _submittedActionType == 'attack_switch') &&
        _submittedActionTargetId == attack['id']) ||
        (_pendingEnforceSwitch && _pendingAttack != null && _pendingAttack!['id'] == attack['id']);
    final enforceSwitch = (attack['meta'] as Map<String, dynamic>?)?['enforce_switch'] as bool? ?? false;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.8) : accentColor.withValues(alpha: 0.45),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: name + stats
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: name + (pp/pp)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (pp != null)
                        TextSpan(
                          text: ' ($pp/$pp)',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                // Row 2: sword + power, bullseye + accuracy
                Row(
                  children: [
                    SvgPicture.string(
                      _swordSvg,
                      width: 8,
                      height: 8,
                      colorFilter: ColorFilter.mode(
                        AppColors.onSurfaceMuted,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      power != null && power > 0 ? '$power' : '—',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SvgPicture.string(
                      _bullseyeSvg,
                      width: 8,
                      height: 8,
                      colorFilter: ColorFilter.mode(
                        AppColors.onSurfaceMuted,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      accuracy != null ? '$accuracy' : '—',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Right: type badge(s) + category label stacked
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (types.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: types.take(2).map((t) => Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: PokemonTypeIcons.getColor(t),
                        shape: BoxShape.circle,
                      ),
                      child: PokemonTypeIcons.buildSvgIcon(
                        t,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  )).toList(),
                ),
              const SizedBox(height: 2),
              Text(
                category,
                style: TextStyle(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () {
        final oppPosition = _oppActive['field_position'] as Map<String, dynamic>?;
        final targetStr = oppPosition != null
            ? '${oppPosition['side']}${oppPosition['group']}'
            : 'B1';

        if (enforceSwitch) {
          setState(() {
            _pendingEnforceSwitch = true;
            _pendingAttack = attack;
            _submittedActionType = null;
            _submittedActionTargetId = null;
            _submittedActionSwitchTargetId = null;
            _battleFeedback.add('$name requiere un cambio. ¿Quién entra al combate?');
          });
          _scrollToFeedbackBottom();
        } else {
          setState(() {
            _submittedActionType = 'attack';
            _submittedActionTargetId = attack['id'];
            _submittedActionSwitchTargetId = null;
            _pendingEnforceSwitch = false;
            _pendingAttack = null;
            _battleFeedback.add('Enviando acción: Usar $name...');
          });
          _scrollToFeedbackBottom();
          _socketService.sendAction('attack', {
            'attack_id': attack['id'],
            'pokemon_id': _myActive['id'] as int,
            'targets': [targetStr],
          });
        }
      },
      child: isDimmed ? Opacity(opacity: 0.45, child: cardContent) : cardContent,
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
              Icon(
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
    final isAnySwitchSelected = _submittedActionType == 'switch' || _submittedActionType == 'attack_switch';
    final switchTargetId = _submittedActionType == 'switch' ? _submittedActionTargetId : _submittedActionSwitchTargetId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
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
                if (isAnySwitchSelected && switchTargetId != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.35), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ENVIADO: ENTRA ${_findMonsterName(switchTargetId).toUpperCase()}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.2,
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
                final isLead = m['lead'] == true;
                final isSelected = (_submittedActionType == 'switch' && _submittedActionTargetId == m['id']) ||
                                   (_submittedActionType == 'attack_switch' && _submittedActionSwitchTargetId == m['id']);
                final monTypes = (m['types'] as List?)?.cast<String>() ?? [];
                final isFainted = (m['hp'] as int) == 0;

                final isDimmed = isFainted || (isAnySwitchSelected && !isSelected);

                final cardContent = Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Row 1: Name & Level (left), Types & LEAD (right)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    m['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nv.${m['level']}',
                                  style: TextStyle(
                                    color: AppColors.onSurfaceMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...monTypes.map((t) => Padding(
                                padding: const EdgeInsets.only(left: 3),
                                child: PokemonTypeIcons.buildTypeBadge(t, fontSize: 8),
                              )),
                            ],
                          ),
                        ],
                      ),

                      // Row 2: Sprite (Max 36x36) and Health Bar (Centered)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (m['sprite_url'] != null && (m['sprite_url'] as String).isNotEmpty) ...[
                            Image.network(
                              m['sprite_url'] as String,
                              height: 36,
                              width: 36,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(width: 36, height: 36),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'HP ${m['hp']}/${m['maxHp']}',
                                  style: TextStyle(
                                    color: AppColors.onSurfaceMuted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 4,
                                    backgroundColor: AppColors.surfaceHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.success.withValues(alpha: 0.9)
                          : (isLead
                              ? AppColors.info.withValues(alpha: 0.7)
                              : AppColors.outlineVariant.withValues(alpha: 0.35)),
                      width: isSelected ? 2.0 : (isLead ? 1.5 : 1.0),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: isFainted || isLead
                          ? null
                          : () {
                        if (_pendingEnforceSwitch) {
                          _submitAttackSwitch(m['id'] as int);
                        } else {
                          setState(() {
                            _submittedActionType = 'switch';
                            _submittedActionTargetId = m['id'];
                            _submittedActionSwitchTargetId = null;
                            _pendingEnforceSwitch = false;
                            _battleFeedback.add('Enviando acción: Cambiar a ${m['name']}...');
                          });
                          _scrollToFeedbackBottom();
                          _socketService.sendAction('switch', {
                            'pokemon_id': m['id'] as int,
                          });
                        }
                      },
                      child: isDimmed ? Opacity(opacity: 0.45, child: cardContent) : cardContent,
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
                Icon(
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

  Widget _buildCompactTopTurnBanner(TextTheme text) {
    final isSyncing = _phase.isSyncing;
    final isError = _phase.isError;
    final isWaitingPlayers = _phase.isWaitingPlayers;
    final isWaiting = _phase.isWaitingActions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSyncing
                ? Icons.sync_rounded
                : (isError
                    ? Icons.error_outline_rounded
                    : (isWaitingPlayers
                        ? Icons.group_add_rounded
                        : Icons.hourglass_empty_rounded)),
            color: AppColors.primary,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            isSyncing
                ? 'Conectando'
                : (isError
                    ? 'Error'
                    : (isWaitingPlayers ? 'Lobby' : 'Turno $_turn')),
            style: text.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 10,
            width: 1,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(width: 8),
          if (isSyncing)
            _PulsingIndicator(color: AppColors.primary)
          else if (isError)
            _PulsingIndicator(color: AppColors.danger)
          else if (isWaitingPlayers)
            _PulsingIndicator(color: AppColors.warning)
          else if (isWaiting)
            _PulsingIndicator(color: AppColors.warning)
          else
            _PulsingIndicator(color: AppColors.primary),
          if (!isSyncing && !isError && !isWaitingPlayers && isWaiting && _remainingSeconds > 0) ...[
            const SizedBox(width: 8),
            Container(
              height: 10,
              width: 1,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.timer_outlined,
              color: AppColors.onSurfaceMuted,
              size: 12,
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 38,
              child: Text(
                _formatDuration(_remainingSeconds),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurfaceMuted,
                ),
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
  final bool isLead;
  final int aliveCount;
  final bool mirror;
  const _ParticipantTile({
    required this.label,
    required this.name,
    required this.color,
    required this.mon,
    this.isLead = false,
    this.aliveCount = 0,
    this.mirror = false,
  });

  Widget _buildStatusBadge(String? status) {
    if (status == null || status.isEmpty || status.toLowerCase() == 'normal') {
      return const SizedBox(height: 16); // placeholder spacer to keep the card height constant!
    }

    final normalized = status.toLowerCase();
    String label = status.toUpperCase();
    Color badgeColor = Colors.grey;

    if (normalized.contains('paral')) {
      label = 'PAR';
      badgeColor = const Color(0xFFF1C40F); // Yellow
    } else if (normalized.contains('burn') || normalized.contains('quem')) {
      label = 'BRN';
      badgeColor = const Color(0xFFE74C3C); // Red
    } else if (normalized.contains('badly') || normalized.contains('toxic') || normalized.contains('tox')) {
      label = 'TOX';
      badgeColor = const Color(0xFF6C3483); // Darker purple (Badly Poisoned)
    } else if (normalized.contains('pois') || normalized.contains('env')) {
      label = 'PSN';
      badgeColor = const Color(0xFF9B59B6); // Regular purple (Poison)
    } else if (normalized.contains('sleep') || normalized.contains('sue')) {
      label = 'SLP';
      badgeColor = const Color(0xFF95A5A6); // Grey
    } else if (normalized.contains('freez') || normalized.contains('congel')) {
      label = 'FRZ';
      badgeColor = const Color(0xFF3498DB); // Blue
    } else if (normalized == 'par') {
      label = 'PAR';
      badgeColor = const Color(0xFFF1C40F);
    } else if (normalized == 'brn') {
      label = 'BRN';
      badgeColor = const Color(0xFFE74C3C);
    } else if (normalized == 'psn') {
      label = 'PSN';
      badgeColor = const Color(0xFF9B59B6);
    } else if (normalized == 'tox') {
      label = 'TOX';
      badgeColor = const Color(0xFF6C3483);
    } else if (normalized == 'slp') {
      label = 'SLP';
      badgeColor = const Color(0xFF95A5A6);
    } else if (normalized == 'frz') {
      label = 'FRZ';
      badgeColor = const Color(0xFF3498DB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pct = (mon['hp'] as num?) != null && (mon['maxHp'] as num?) != null && (mon['maxHp'] as num) > 0
        ? (mon['hp'] as num) / (mon['maxHp'] as num)
        : 0.0;

    Color hpColor = AppColors.success;
    if (pct < 0.5) hpColor = AppColors.accent;
    if (pct < 0.25) hpColor = AppColors.danger;

    final textInfo = Expanded(
      child: Column(
        crossAxisAlignment: mirror ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: mirror ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: mirror
                ? [
                    Text(
                      'Nv.${mon['level'] ?? 50}',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        mon['name'] ?? '?',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.catching_pokemon, color: color, size: 14),
                  ]
                : [
                    Icon(Icons.catching_pokemon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        mon['name'] ?? '?',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Nv.${mon['level'] ?? 50}',
                      style: text.bodySmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: mirror ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              _buildStatusBadge(mon['status']),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: mirror
                ? [
                    Text(
                      '${mon['hp'] ?? 0}/${mon['maxHp'] ?? 100}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                        ),
                      ),
                    ),
                  ]
                : [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 5,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(hpColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${mon['hp'] ?? 0}/${mon['maxHp'] ?? 100}',
                      style: TextStyle(
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

    final spriteImage = mon['sprite_url'] != null && (mon['sprite_url'] as String).isNotEmpty
        ? SizedBox(
            height: 70,
            width: 70,
            child: Image.network(
              mon['sprite_url'],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(width: 70, height: 70),
            ),
          )
        : const SizedBox(width: 70, height: 70);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isLead ? color.withValues(alpha: 0.8) : color.withValues(alpha: 0.35),
          width: isLead ? 1.8 : 1.0,
        ),
      ),
      child: Row(
        children: mirror
            ? [
                spriteImage,
                const SizedBox(width: 8),
                textInfo,
              ]
            : [
                textInfo,
                const SizedBox(width: 8),
                spriteImage,
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

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        widget.icon,
        color: widget.color,
        size: 24,
      ),
    );
  }
}

enum BattlePhase {
  syncing,
  waitingPlayers,
  settingUp,
  waitingActions,
  resolving,
  finished,
  error;

  bool get isSyncing => this == BattlePhase.syncing;
  bool get isWaitingPlayers => this == BattlePhase.waitingPlayers;
  bool get isSettingUp => this == BattlePhase.settingUp;
  bool get isWaitingActions => this == BattlePhase.waitingActions;
  bool get isError => this == BattlePhase.error;

  static BattlePhase fromString(String? value) {
    switch (value) {
      case 'syncing':
        return BattlePhase.syncing;
      case 'waiting_players':
        return BattlePhase.waitingPlayers;
      case 'setting_up':
        return BattlePhase.settingUp;
      case 'waiting_actions':
        return BattlePhase.waitingActions;
      case 'resolving':
        return BattlePhase.resolving;
      case 'finished':
        return BattlePhase.finished;
      case 'error':
        return BattlePhase.error;
      default:
        return BattlePhase.error;
    }
  }

  String toJsonString() {
    switch (this) {
      case BattlePhase.syncing:
        return 'syncing';
      case BattlePhase.waitingPlayers:
        return 'waiting_players';
      case BattlePhase.settingUp:
        return 'setting_up';
      case BattlePhase.waitingActions:
        return 'waiting_actions';
      case BattlePhase.resolving:
        return 'resolving';
      case BattlePhase.finished:
        return 'finished';
      case BattlePhase.error:
        return 'error';
    }
  }
}

const String _crossedSwordsSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polyline points="14.5 17.5 3 6 3 3 6 3 17.5 14.5" />
  <line x1="13" x2="19" y1="19" y2="13" />
  <line x1="16" x2="20" y1="16" y2="20" />
  <line x1="19" x2="21" y1="21" y2="19" />
  <polyline points="14.5 6.5 18 3 21 3 21 6 17.5 9.5" />
  <line x1="5" x2="9" y1="14" y2="18" />
  <line x1="7" x2="4" y1="17" y2="20" />
  <line x1="3" x2="5" y1="19" y2="21" />
</svg>
''';



const String _swordSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polyline points="14.5 17.5 3 6 3 3 6 3 17.5 14.5" />
  <line x1="13" y1="19" x2="19" y2="13" />
  <line x1="16" y1="16" x2="20" y2="20" />
  <line x1="19" y1="21" x2="21" y2="19" />
</svg>
''';

const String _bullseyeSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10" />
  <circle cx="12" cy="12" r="6" />
  <circle cx="12" cy="12" r="2" fill="currentColor" />
</svg>
''';

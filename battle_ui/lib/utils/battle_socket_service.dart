// ignore_for_file: avoid_print
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'config.dart';

/// Service to manage WebSocket connections with Elixir Phoenix Channels
class BattleSocketService with ChangeNotifier {
  PhoenixSocket? _socket;
  PhoenixChannel? _applicationChannel;
  PhoenixChannel? _playerChannel;
  PhoenixChannel? _battleChannel;
  PhoenixChannel? _chatChannel;

  StreamSubscription? _appMessageSub;
  StreamSubscription? _playerMessageSub;
  StreamSubscription? _battleMessageSub;
  StreamSubscription? _chatMessageSub;

  // Track the active player profile in memory
  Map<String, dynamic>? _currentPlayer;
  Map<String, dynamic>? get currentPlayer => _currentPlayer;

  // Track active battles from the player profile
  List<Map<String, dynamic>> _activeBattles = [];
  List<Map<String, dynamic>> get activeBattles => _activeBattles;

  // Active users count
  int _activeUsersCount = 0;
  int get activeUsersCount => _activeUsersCount;

  // Presence map
  Map<String, dynamic> _presences = {};

  // Controllers for streams
  final _battleEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _activeUsersController = StreamController<int>.broadcast();
  final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _battleCreatedController = StreamController<String>.broadcast();
  final _battleJoinedController = StreamController<String>.broadcast();

  /// Stream of raw incoming battle event payloads
  Stream<Map<String, dynamic>> get battleEvents => _battleEventController.stream;

  /// Stream of player profile updates
  Stream<Map<String, dynamic>> get playerEvents => _playerEventController.stream;

  /// Stream of active online users count
  Stream<int> get activeUsersStream => _activeUsersController.stream;

  /// Stream of raw incoming chat message payloads
  Stream<Map<String, dynamic>> get chatEvents => _chatMessageController.stream;

  /// Stream of battle creation events (emits battleId)
  Stream<String> get battleCreatedEvents => _battleCreatedController.stream;

  /// Stream of battle join events (emits battleId)
  Stream<String> get battleJoinedEvents => _battleJoinedController.stream;

  /// Check whether the socket is currently connected
  bool get isConnected => _socket?.isConnected ?? false;

  /// Ensure the socket connection is initialized
  void _ensureSocketConnected() {
    if (_socket != null && _socket!.isConnected) return;

    if (_socket != null) {
      _socket!.dispose();
    }

    print("Conectando al WebSocket de Phoenix: ${AppConfig.websocketUrl}");
    _socket = PhoenixSocket(AppConfig.websocketUrl);

    _socket!.openStream.listen((_) {
      print("¡Phoenix WebSocket conectado exitosamente!");
      connectAndJoinLobby();
    });
    _socket!.closeStream.listen((_) => print("Phoenix WebSocket cerrado."));
    _socket!.errorStream.listen((err) => print("Error en Phoenix WebSocket: $err"));

    _socket!.connect();
  }

  /// Connects to the socket and joins the application channel for Presence tracking
  void connectAndJoinLobby() {
    _ensureSocketConnected();

    if (_applicationChannel != null) return; // Already joined

    print("Uniéndose al canal 'application'...");
    _applicationChannel = _socket!.addChannel(topic: 'application');
    final joinResponse = _applicationChannel!.join();

    joinResponse.onReply("ok", (response) {
      print("Unido con éxito al canal 'application'");
    });
    joinResponse.onReply("error", (response) {
      print("Error al unirse al canal 'application': $response");
    });

    _appMessageSub = _applicationChannel!.messages.listen((Message message) {
      final event = message.event.value;
      final payload = message.payload;
      if (payload == null) return;

      if (event == 'presence_state') {
        _handlePresenceState(payload);
      } else if (event == 'presence_diff') {
        _handlePresenceDiff(payload);
      }
    });
  }

  /// Register a player by joining a temporary channel player:{name}
  /// and pushing the register action on the same channel.
  Future<Map<String, dynamic>> registerPlayer(String name) {
    _ensureSocketConnected();

    final completer = Completer<Map<String, dynamic>>();

    // Join temporary channel player:{name}
    final tempTopic = 'player:$name';
    print("Uniéndose al canal temporal: $tempTopic");
    final tempChannel = _socket!.addChannel(topic: tempTopic);
    final joinResponse = tempChannel.join();

    StreamSubscription? tempSub;
    tempSub = tempChannel.messages.listen((Message message) {
      final event = message.event.value;
      final payload = message.payload;

      if (event == 'player_event' && payload != null) {
        final innerEvent = payload['event'];
        final innerPayload = payload['payload'];

        if (innerEvent == 'info' && innerPayload != null && innerPayload['player'] != null) {
          final playerProfile = innerPayload['player'] as Map<String, dynamic>;
          print("Registro exitoso recibido para ${playerProfile['name']}: ID ${playerProfile['id']}");

          // Save profile
          _currentPlayer = playerProfile;
          final rawBattles = (innerPayload['battles'] ?? playerProfile['battles']) as List?;
          _activeBattles = rawBattles != null
              ? rawBattles.map((b) => Map<String, dynamic>.from(b as Map)).toList()
              : [];
          _playerEventController.add(playerProfile);
          notifyListeners();

          // Clean up temp channel
          tempSub?.cancel();
          tempChannel.leave();
          tempChannel.close();

          // Join permanent player channel
          _joinPermanentPlayerChannel(playerProfile['id'].toString());

          if (!completer.isCompleted) {
            completer.complete(playerProfile);
          }
        }
      }
    });

    joinResponse.onReply("ok", (_) {
      print("Conectado a $tempTopic. Enviando acción 'register'...");
      tempChannel.push('register', {});
    });

    // Timeout fallback (10s)
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        tempSub?.cancel();
        tempChannel.leave();
        tempChannel.close();
        completer.completeError(TimeoutException("El registro excedió el tiempo límite (10s)"));
      }
    });

    return completer.future;
  }

  void _joinPermanentPlayerChannel(String playerId) {
    if (_playerChannel != null) {
      _playerMessageSub?.cancel();
      _playerChannel!.leave();
      _playerChannel!.close();
    }

    final topic = 'player:$playerId';
    print("Uniéndose al canal permanente del jugador: $topic");
    _playerChannel = _socket!.addChannel(topic: topic);
    _playerChannel!.join();

    _playerMessageSub = _playerChannel!.messages.listen((Message message) {
      final event = message.event.value;
      final payload = message.payload;

      // Handle any player-specific events here
      if (event == 'player_event' && payload != null) {
        final innerEvent = payload['event'];
        final innerPayload = payload['payload'];

        if (innerEvent == 'info' && innerPayload != null && innerPayload['player'] != null) {
          final playerProfile = innerPayload['player'] as Map<String, dynamic>;
          _currentPlayer = playerProfile;
          final rawBattles = (innerPayload['battles'] ?? playerProfile['battles']) as List?;
          _activeBattles = rawBattles != null
              ? rawBattles.map((b) => Map<String, dynamic>.from(b as Map)).toList()
              : [];
          _playerEventController.add(_currentPlayer!);
          notifyListeners();
        } else if (innerEvent == 'battle_created' && innerPayload != null) {
          final battleId = innerPayload['battle_id']?.toString() ?? '';
          print("Evento battle_created recibido. Battle ID: $battleId");
          _battleCreatedController.add(battleId);
        } else if (innerEvent == 'battle_joined' && innerPayload != null) {
          final battleId = innerPayload['battle_id']?.toString() ?? '';
          print("Evento battle_joined recibido. Battle ID: $battleId");
          _battleJoinedController.add(battleId);
        }
      }
    });
  }

  /// Establish WebSocket connection and join a specific battle channel
  void connectToBattle(String battleId) {
    _ensureSocketConnected();

    // Clean up existing battle channel if any
    leaveBattle();

    print("Uniéndose al canal battle:$battleId");
    final battleParams = {
      'player_id': _currentPlayer?['id']?.toString() ?? '',
      'username': _currentPlayer?['name'] ?? 'Entrenador',
    };
    _battleChannel = _socket!.addChannel(topic: 'battle:$battleId', parameters: battleParams);

    final joinResponse = _battleChannel!.join();
    joinResponse.onReply("ok", (response) {
      print("Unido con éxito al canal battle:$battleId");
    });
    joinResponse.onReply("error", (response) {
      print("Fallo al unirse al canal battle:$battleId: $response");
    });

    _battleMessageSub = _battleChannel!.messages.listen((Message message) {
      if (message.event.value == 'battle_event' && message.payload != null) {
        _battleEventController.add(message.payload!);
      }
    });

    print("Uniéndose al canal battle_chat:$battleId");
    final chatParams = {
      'username': _currentPlayer?['name'] ?? 'Anonymous',
      'player_id': _currentPlayer?['id']?.toString() ?? '',
    };
    _chatChannel = _socket!.addChannel(topic: 'battle_chat:$battleId', parameters: chatParams);

    final chatJoinResponse = _chatChannel!.join();
    chatJoinResponse.onReply("ok", (response) {
      print("Unido con éxito al canal battle_chat:$battleId");
    });
    chatJoinResponse.onReply("error", (response) {
      print("Fallo al unirse al canal battle_chat:$battleId: $response");
    });

    _chatMessageSub = _chatChannel!.messages.listen((Message message) {
      if (message.event.value == 'new_message' && message.payload != null) {
        _chatMessageController.add(message.payload!);
      }
    });
  }

  /// Push a combat action to the Elixir backend (calls handle_in("action", ...))
  void sendAction(String actionType, Map<String, dynamic> payload) {
    if (_battleChannel != null && _battleChannel!.state == PhoenixChannelState.joined) {
      _battleChannel!.push(
        'action',
        {
          'action': actionType,
          ...payload,
        },
      );
    } else {
      print("Advertencia: No se pudo enviar la acción porque el canal no está listo.");
    }
  }

  /// Request creation of a new battle
  void createBattle() {
    if (_playerChannel != null && _playerChannel!.state == PhoenixChannelState.joined) {
      print("Enviando evento create_battle al canal player");
      _playerChannel!.push('create_battle', {});
    } else {
      print("Advertencia: No se pudo enviar create_battle porque el canal del jugador no está listo.");
    }
  }

  /// Request joining an existing battle
  void joinBattle(String battleId) {
    if (_playerChannel != null && _playerChannel!.state == PhoenixChannelState.joined) {
      print("Enviando evento join_battle con ID $battleId al canal player");
      _playerChannel!.push('join_battle', {'battle_id': battleId});
    } else {
      print("Advertencia: No se pudo enviar join_battle porque el canal del jugador no está listo.");
    }
  }

  /// Push a chat message to the Phoenix backend
  void sendChatMessage(String body) {
    if (_chatChannel != null && _chatChannel!.state == PhoenixChannelState.joined) {
      _chatChannel!.push('send_message', {'body': body});
    } else {
      print("Advertencia: No se pudo enviar el mensaje porque el canal de chat no está listo.");
    }
  }

  /// Leave the battle channel
  void leaveBattle() {
    _battleMessageSub?.cancel();
    _battleMessageSub = null;

    if (_battleChannel != null) {
      _battleChannel!.leave();
      _battleChannel!.close();
      _battleChannel = null;
    }

    _chatMessageSub?.cancel();
    _chatMessageSub = null;

    if (_chatChannel != null) {
      _chatChannel!.leave();
      _chatChannel!.close();
      _chatChannel = null;
    }
  }

  /// Disconnect and clean up all resources
  void disconnect() {
    leaveBattle();

    _appMessageSub?.cancel();
    _appMessageSub = null;
    if (_applicationChannel != null) {
      _applicationChannel!.leave();
      _applicationChannel!.close();
      _applicationChannel = null;
    }

    _playerMessageSub?.cancel();
    _playerMessageSub = null;
    if (_playerChannel != null) {
      _playerChannel!.leave();
      _playerChannel!.close();
      _playerChannel = null;
    }

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _currentPlayer = null;
    _activeBattles.clear();
    _presences.clear();
    _activeUsersCount = 0;
    notifyListeners();
  }

  /// Dispose the service
  @override
  void dispose() {
    disconnect();
    _battleEventController.close();
    _playerEventController.close();
    _activeUsersController.close();
    _chatMessageController.close();
    _battleCreatedController.close();
    _battleJoinedController.close();
    super.dispose();
  }

  // --- Presence Handling Helpers ---

  void _handlePresenceState(Map<String, dynamic> payload) {
    _presences = Map<String, dynamic>.from(payload);
    _updateActiveCount();
  }

  void _handlePresenceDiff(Map<String, dynamic> payload) {
    final joins = payload['joins'] as Map<String, dynamic>? ?? {};
    final leaves = payload['leaves'] as Map<String, dynamic>? ?? {};

    // Sync joins
    joins.forEach((key, value) {
      if (value is Map && value.containsKey('metas')) {
        final newMetas = value['metas'] as List? ?? [];
        if (!_presences.containsKey(key)) {
          _presences[key] = {'metas': List.from(newMetas)};
        } else {
          final existingVal = _presences[key];
          if (existingVal is Map && existingVal.containsKey('metas')) {
            final existingMetas = List.from(existingVal['metas'] as List);
            for (var newMeta in newMetas) {
              if (newMeta is Map) {
                final phxRef = newMeta['phx_ref'];
                // Evitar duplicados
                existingMetas.removeWhere((m) => m is Map && m['phx_ref'] == phxRef);
                existingMetas.add(newMeta);
              }
            }
            _presences[key] = {'metas': existingMetas};
          } else {
            _presences[key] = {'metas': List.from(newMetas)};
          }
        }
      }
    });

    // Sync leaves
    leaves.forEach((key, value) {
      if (value is Map && value.containsKey('metas')) {
        final oldMetas = value['metas'] as List? ?? [];
        if (_presences.containsKey(key)) {
          final existingVal = _presences[key];
          if (existingVal is Map && existingVal.containsKey('metas')) {
            final existingMetas = List.from(existingVal['metas'] as List);
            for (var oldMeta in oldMetas) {
              if (oldMeta is Map) {
                final phxRef = oldMeta['phx_ref'];
                existingMetas.removeWhere((m) => m is Map && m['phx_ref'] == phxRef);
              }
            }
            if (existingMetas.isEmpty) {
              _presences.remove(key);
            } else {
              _presences[key] = {'metas': existingMetas};
            }
          }
        }
      }
    });

    _updateActiveCount();
  }

  void _updateActiveCount() {
    int count = 0;
    if (_presences.containsKey('lobby')) {
      final lobbyData = _presences['lobby'] as Map<String, dynamic>?;
      final metas = lobbyData?['metas'] as List?;
      count = metas?.length ?? 0;
    } else {
      _presences.forEach((key, value) {
        if (value is Map && value.containsKey('metas')) {
          final metas = value['metas'] as List?;
          count += metas?.length ?? 0;
        }
      });
    }
    _activeUsersCount = count;
    _activeUsersController.add(count);
    notifyListeners();
  }
}

// ignore_for_file: avoid_print
import 'dart:async';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'config.dart';

/// Service to manage WebSocket connections with Elixir Phoenix Channels
class BattleSocketService {
  PhoenixSocket? _socket;
  PhoenixChannel? _applicationChannel;
  PhoenixChannel? _playerChannel;
  PhoenixChannel? _battleChannel;

  StreamSubscription? _appMessageSub;
  StreamSubscription? _playerMessageSub;
  StreamSubscription? _battleMessageSub;

  // Track the active player profile in memory
  Map<String, dynamic>? _currentPlayer;
  Map<String, dynamic>? get currentPlayer => _currentPlayer;

  // Active users count
  int _activeUsersCount = 0;
  int get activeUsersCount => _activeUsersCount;

  // Presence map
  Map<String, dynamic> _presences = {};

  // Controllers for streams
  final _battleEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _playerEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _activeUsersController = StreamController<int>.broadcast();

  /// Stream of raw incoming battle event payloads
  Stream<Map<String, dynamic>> get battleEvents => _battleEventController.stream;

  /// Stream of player profile updates
  Stream<Map<String, dynamic>> get playerEvents => _playerEventController.stream;

  /// Stream of active online users count
  Stream<int> get activeUsersStream => _activeUsersController.stream;

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
  /// and pushing the register action on the battle_game channel.
  Future<Map<String, dynamic>> registerPlayer(String name) {
    _ensureSocketConnected();

    final completer = Completer<Map<String, dynamic>>();

    // 1. Join temporary channel player:{name}
    final tempTopic = 'player:$name';
    print("Uniéndose al canal temporal: $tempTopic");
    final tempChannel = _socket!.addChannel(topic: tempTopic);
    tempChannel.join();

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
          _playerEventController.add(playerProfile);

          // Clean up temp channel
          tempSub?.cancel();
          tempChannel.leave();

          // Join permanent player channel
          _joinPermanentPlayerChannel(playerProfile['id'].toString());

          if (!completer.isCompleted) {
            completer.complete(playerProfile);
          }
        }
      }
    });

    // 2. Join battle_game and push "register"
    final gameChannel = _socket!.addChannel(topic: 'battle_game');
    final gameJoin = gameChannel.join();
    gameJoin.onReply("ok", (_) {
      print("Enviando acción 'register' para el nombre '$name'");
      gameChannel.push('register', {'name': name});
    });

    // Timeout fallback (10s)
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        tempSub?.cancel();
        tempChannel.leave();
        gameChannel.leave();
        completer.completeError(TimeoutException("El registro excedió el tiempo límite (10s)"));
      }
    });

    return completer.future;
  }

  void _joinPermanentPlayerChannel(String playerId) {
    if (_playerChannel != null) {
      _playerMessageSub?.cancel();
      _playerChannel!.leave();
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
        final innerPayload = payload['payload'];
        if (innerPayload != null && innerPayload['player'] != null) {
          _currentPlayer = innerPayload['player'] as Map<String, dynamic>;
          _playerEventController.add(_currentPlayer!);
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
    _battleChannel = _socket!.addChannel(topic: 'battle:$battleId');

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

  /// Leave the battle channel
  void leaveBattle() {
    _battleMessageSub?.cancel();
    _battleMessageSub = null;

    if (_battleChannel != null) {
      _battleChannel!.leave();
      _battleChannel = null;
    }
  }

  /// Disconnect and clean up all resources
  void disconnect() {
    leaveBattle();

    _appMessageSub?.cancel();
    _appMessageSub = null;
    if (_applicationChannel != null) {
      _applicationChannel!.leave();
      _applicationChannel = null;
    }

    _playerMessageSub?.cancel();
    _playerMessageSub = null;
    if (_playerChannel != null) {
      _playerChannel!.leave();
      _playerChannel = null;
    }

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _currentPlayer = null;
    _presences.clear();
    _activeUsersCount = 0;
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _battleEventController.close();
    _playerEventController.close();
    _activeUsersController.close();
  }

  // --- Presence Handling Helpers ---

  void _handlePresenceState(Map<String, dynamic> payload) {
    _presences = Map<String, dynamic>.from(payload);
    _updateActiveCount();
  }

  void _handlePresenceDiff(Map<String, dynamic> payload) {
    final joins = payload['joins'] as Map<String, dynamic>? ?? {};
    final leaves = payload['leaves'] as Map<String, dynamic>? ?? {};

    joins.forEach((key, value) {
      _presences[key] = value;
    });

    leaves.forEach((key, value) {
      _presences.remove(key);
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
  }
}

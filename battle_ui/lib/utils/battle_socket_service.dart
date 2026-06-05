import 'dart:async';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'config.dart';

/// Service to manage WebSocket connections with Elixir Phoenix Channels
class BattleSocketService {
  PhoenixSocket? _socket;
  PhoenixChannel? _channel;
  StreamSubscription? _messageSubscription;

  // Broadcast stream controller to notify UI of incoming game events
  final _battleEventController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of raw incoming battle event payloads
  Stream<Map<String, dynamic>> get battleEvents => _battleEventController.stream;

  /// Check whether the socket is currently connected
  bool get isConnected => _socket?.isConnected ?? false;

  /// Establish WebSocket connection and join a specific battle channel
  void connectToBattle(String battleId) {
    // Clean up any existing connection first
    disconnect();

    print("Connecting to Elixir Phoenix WebSocket at: ${AppConfig.websocketUrl}");

    // 1. Initialize PhoenixSocket from the package
    _socket = PhoenixSocket(AppConfig.websocketUrl);

    // Subscribe to socket events for debugging and connection lifecycle
    _socket!.openStream.listen((_) => print("¡Phoenix WebSocket conectado exitosamente!"));
    _socket!.closeStream.listen((_) => print("Phoenix WebSocket cerrado."));
    _socket!.errorStream.listen((err) => print("Error en Phoenix WebSocket: $err"));

    // Connect physically to the server
    _socket!.connect();

    // 2. Add channel for 'battle:ID' and join
    _channel = _socket!.addChannel(topic: 'battle:$battleId');

    final joinResponse = _channel!.join();
    joinResponse.onReply("ok", (response) {
      print("Unido con éxito al canal battle:$battleId");
    });
    joinResponse.onReply("error", (response) {
      print("Fallo al unirse al canal battle:$battleId: $response");
    });

    // 3. Listen for incoming channel messages
    _messageSubscription = _channel!.messages.listen((Message message) {
      // Look for custom battle_event pushed by Elixir
      if (message.event.value == 'battle_event' && message.payload != null) {
        _battleEventController.add(message.payload!);
      }
    });
  }

  /// Push a combat action to the Elixir backend (calls handle_in("action", ...))
  void sendAction(String actionType, Map<String, dynamic> payload) {
    if (_channel != null && _channel!.state == PhoenixChannelState.joined) {
      _channel!.push(
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

  /// Disconnect and clean up current channel and socket resources
  void disconnect() {
    _messageSubscription?.cancel();
    _messageSubscription = null;

    if (_channel != null) {
      _channel!.leave();
      _channel = null;
    }

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _battleEventController.close();
  }
}

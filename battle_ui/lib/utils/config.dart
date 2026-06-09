class AppConfig {
  /// The WebSocket URL for the Elixir/Phoenix backend.
  /// Loadable via --dart-define-from-file=config.json
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'ws://127.0.0.1:4000/socket/websocket',
  );
}

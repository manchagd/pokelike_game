class AppConfig {
  /// The WebSocket URL for the Elixir/Phoenix backend.
  /// Loadable via --dart-define-from-file=config.json
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'ws://localhost:4000/socket/websocket',
  );
}

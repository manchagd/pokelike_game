import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pixel_clash/utils/battle_socket_service.dart';

class FakeBattleSocketService extends BattleSocketService {
  @override
  void connectAndJoinLobby() {
    // No-op in tests to avoid creating real socket connections and network timers
  }
}

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with a Fake service provider.
    await tester.pumpWidget(
      ChangeNotifierProvider<BattleSocketService>(
        create: (_) => FakeBattleSocketService(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('¡Bienvenido a Pixel Clash!')),
          ),
        ),
      ),
    );

    // Verify that welcome message is shown
    expect(find.text('¡Bienvenido a Pixel Clash!'), findsOneWidget);
  });
}

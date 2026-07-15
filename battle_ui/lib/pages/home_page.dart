import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mix/mix.dart';
import '../theme.dart';
import '../widgets/sidebar.dart';
import '../utils/battle_socket_service.dart';
import 'matches_view.dart';
import 'team_builder_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Connect to the lobby immediately on app startup
    context.read<BattleSocketService>().connectAndJoinLobby();
  }

  final List<Widget> _views = const [
    MatchesView(),
    TeamBuilderView(),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final socketService = context.watch<BattleSocketService>();
    final profile = socketService.currentPlayer;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: profile == null
                ? _buildWelcomeScreen(text)
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.02, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_selectedIndex),
                      child: _views[_selectedIndex],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

BoxStyler get _welcomeCardStyle => BoxStyler()
  .width(520)
  .margin(EdgeInsetsGeometryMix.all(32))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.lg))
  .linearGradient(
    colors: [
      AppColors.surface,
      AppColors.surfaceHigh.withValues(alpha: 0.95),
      AppColors.background,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  )
  .border(BorderMix.all(BorderSideMix(
    color: AppColors.primary.withValues(alpha: 0.2),
    width: 1.5,
  )))
  .shadow(BoxShadowMix(
    color: AppColors.primary.withValues(alpha: 0.08),
    blurRadius: 40.0,
    spreadRadius: 2.0,
  ))
  .padding(EdgeInsetsGeometryMix.all(40));

BoxStyler get _circleIconStyle => BoxStyler()
  .padding(EdgeInsetsGeometryMix.all(20))
  .borderRadius(BorderRadiusGeometryMix.circular(100))
  .color(AppColors.primary.withValues(alpha: 0.1))
  .border(BorderMix.all(BorderSideMix(
    color: AppColors.primary.withValues(alpha: 0.3),
  )));

TextStyler _titleStyle(TextTheme text) => TextStyler()
  .fontSize(text.headlineSmall?.fontSize ?? 24.0)
  .fontWeight(FontWeight.w800)
  .letterSpacing(0.5)
  .textAlign(TextAlign.center);

TextStyler _descStyle(TextTheme text) => TextStyler()
  .fontSize(text.bodyMedium?.fontSize ?? 14.0)
  .color(AppColors.onSurfaceMuted)
  .height(1.5)
  .textAlign(TextAlign.center);

  Widget _buildWelcomeScreen(TextTheme text) {
    return Center(
      child: SingleChildScrollView(
        child: Box(
          style: _welcomeCardStyle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Box(
                style: _circleIconStyle,
                child: Icon(
                  Icons.catching_pokemon,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              StyledText(
                '¡Bienvenido a Pixel Clash!',
                style: _titleStyle(text),
              ),
              const SizedBox(height: 12),
              StyledText(
                'Para unirte a la arena de combate y empezar a desafiar oponentes, por favor ingresa tu nombre de entrenador en el panel lateral.',
                style: _descStyle(text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

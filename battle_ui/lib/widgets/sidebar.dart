import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mix/mix.dart';
import '../theme.dart';
import '../utils/battle_socket_service.dart';
import '../utils/pokemon_type_icons.dart';
import '../utils/theme_provider.dart';

final _sidebarStyle = BoxStyler()
  .width(300)
  .color(AppColors.surface)
  .border(BorderMix.right(BorderSideMix(color: AppColors.outlineVariant, width: 1)));

final _onlineStatusDotStyle = BoxStyler()
  .width(8)
  .height(8)
  .borderRadius(BorderRadiusGeometryMix.circular(4))
  .color(AppColors.success);

final _themeSelectorContainerStyle = BoxStyler()
  .padding(EdgeInsetsGeometryMix.all(4))
  .color(AppColors.surfaceHigh)
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .border(BorderMix.all(BorderSideMix(color: AppColors.outlineVariant)));

final _logoBoxStyle = BoxStyler()
  .width(44)
  .height(44)
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .linearGradient(
    colors: AppColors.logoGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  )
  .shadow(BoxShadowMix(
    color: AppColors.primary.withValues(alpha: 0.45),
    blurRadius: 16,
    offset: const Offset(0, 6),
  ));

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _registerTrainer(BattleSocketService service) async {
    final name = _usernameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    try {
      await service.registerPlayer(name);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegistering = false;
          _errorMessage = e.toString().contains("Timeout")
              ? "Error de conexión."
              : "Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final socketService = context.watch<BattleSocketService>();
    final profile = socketService.currentPlayer;

    return Box(
      style: _sidebarStyle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Box(
                  style: _logoBoxStyle,
                  child: const Icon(Icons.catching_pokemon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: AppColors.logoGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Pixel Clash',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Profile card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: profile == null
                    ? _buildEditProfile(text, socketService)
                    : _buildShowProfile(text, colors, profile, socketService),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Menu label & navigation items (only if profile is registered)
          if (profile != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'MENÚ',
                style: text.labelSmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _NavItem(
              icon: Icons.sports_esports,
              title: 'Arena de Batalla',
              selected: widget.selectedIndex == 0,
              onTap: () => widget.onItemSelected(0),
            ),
            _NavItem(
              icon: Icons.shield_outlined,
              title: 'Constructor de Equipos',
              selected: widget.selectedIndex == 1,
              onTap: () => widget.onItemSelected(1),
            ),
          ],

          const Spacer(),
          _buildThemeSelector(context, text, colors),
          _buildTypeLegend(text),
        ],
      ),
    );
  }

  Widget _buildTypeLegend(TextTheme text) {
    const allTypes = [
      'normal', 'fire', 'water', 'electric', 'grass', 'ice',
      'fighting', 'poison', 'ground', 'flying', 'psychic', 'bug',
      'rock', 'ghost', 'dragon', 'dark', 'steel', 'fairy'
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEYENDA DE TIPOS',
            style: text.labelSmall?.copyWith(
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allTypes.map((type) {
              return Tooltip(
                message: type.toUpperCase(),
                child: PokemonTypeIcons.buildTypeIcon(type, size: 16),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfile(TextTheme text, BattleSocketService service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ENTRENADOR',
          style: text.labelSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _usernameController,
          enabled: !_isRegistering,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu nombre',
            counterText: '',
          ),
          onSubmitted: (_) => _registerTrainer(service),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
        const SizedBox(height: 12),
        _isRegistering
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : FilledButton.icon(
                onPressed: () => _registerTrainer(service),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Confirmar'),
              ),
      ],
    );
  }

  Widget _buildShowProfile(TextTheme text, ColorScheme colors, Map<String, dynamic> profile, BattleSocketService service) {
    final name = profile['name'] as String? ?? 'Entrenador';
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withValues(alpha: 0.18),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: text.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(
                children: [
                  Box(
                    style: _onlineStatusDotStyle,
                  ),
                  const SizedBox(width: 6),
                  Text('En línea', style: text.bodySmall?.copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Desconectar',
          onPressed: () {
            _usernameController.clear();
            setState(() {
              _isRegistering = false;
              _errorMessage = null;
            });
            service.disconnect();
          },
          icon: Icon(Icons.logout, size: 18, color: AppColors.danger),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, TextTheme text, ColorScheme colors) {
    final themeProvider = context.watch<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEMA',
            style: text.labelSmall?.copyWith(
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Box(
            style: _themeSelectorContainerStyle,
            child: Row(
              children: [
                Expanded(
                  child: _ThemeOptionButton(
                    icon: Icons.light_mode_outlined,
                    label: 'Claro',
                    isSelected: currentMode == ThemeMode.light,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                ),
                Expanded(
                  child: _ThemeOptionButton(
                    icon: Icons.dark_mode_outlined,
                    label: 'Oscuro',
                    isSelected: currentMode == ThemeMode.dark,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                ),
                Expanded(
                  child: _ThemeOptionButton(
                    icon: Icons.settings_suggest_outlined,
                    label: 'Sistema',
                    isSelected: currentMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

BoxStyler _navItemStyle(bool selected) => BoxStyler()
  .padding(EdgeInsetsGeometryMix.symmetric(horizontal: 14, vertical: 12))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.md))
  .color(selected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent)
  .onHovered(BoxStyler().color(selected ? AppColors.primary.withValues(alpha: 0.20) : AppColors.primary.withValues(alpha: 0.08)))
  .animate(AnimationConfig.ease(const Duration(milliseconds: 150)));

TextStyler _navItemTextStyle(bool selected) => TextStyler()
  .color(selected ? AppColors.onSurface : AppColors.onSurfaceMuted)
  .fontWeight(selected ? FontWeight.w700 : FontWeight.w500)
  .overflow(TextOverflow.ellipsis);

BoxStyler _themeOptionStyle(bool isSelected) => BoxStyler()
  .padding(EdgeInsetsGeometryMix.symmetric(vertical: 8))
  .borderRadius(BorderRadiusGeometryMix.circular(AppRadius.sm))
  .color(isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent)
  .onHovered(BoxStyler().color(isSelected ? AppColors.primary.withValues(alpha: 0.20) : AppColors.primary.withValues(alpha: 0.08)))
  .animate(AnimationConfig.ease(const Duration(milliseconds: 150)));

TextStyler _themeOptionTextStyle(bool isSelected) => TextStyler()
  .fontSize(10)
  .color(isSelected ? AppColors.primary : AppColors.onSurfaceMuted)
  .fontWeight(isSelected ? FontWeight.w700 : FontWeight.w500);

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: PressableBox(
        onPress: onTap,
        style: _navItemStyle(selected),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primary : AppColors.onSurfaceMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StyledText(
                title,
                style: _navItemTextStyle(selected),
              ),
            ),
            if (selected)
              Box(
                style: BoxStyler()
                  .width(6)
                  .height(6)
                  .color(AppColors.primary)
                  .borderRadius(BorderRadiusGeometryMix.circular(3)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PressableBox(
      onPress: onTap,
      style: _themeOptionStyle(isSelected),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? colors.primary : AppColors.onSurfaceMuted,
          ),
          const SizedBox(height: 4),
          StyledText(
            label,
            style: _themeOptionTextStyle(isSelected),
          ),
        ],
      ),
    );
  }
}

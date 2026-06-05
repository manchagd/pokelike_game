import 'package:flutter/material.dart';
import '../theme.dart';

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
  bool _isEditingUsername = true;
  String _username = '';

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _saveUsername() {
    if (_usernameController.text.trim().isNotEmpty) {
      setState(() {
        _username = _usernameController.text.trim();
        _isEditingUsername = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.logoGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryA0.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.catching_pokemon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
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
                child: _isEditingUsername ? _buildEditProfile(text) : _buildShowProfile(text, colors),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Menu label
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

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEditProfile(TextTheme text) {
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
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ingresa tu nombre'),
          onSubmitted: (_) => _saveUsername(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _saveUsername,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _buildShowProfile(TextTheme text, ColorScheme colors) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withValues(alpha: 0.18),
          child: Text(
            _username.isNotEmpty ? _username[0].toUpperCase() : '?',
            style: text.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_username, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('En línea', style: text.bodySmall?.copyWith(color: AppColors.onSurfaceMuted)),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Editar',
          onPressed: () {
            setState(() {
              _isEditingUsername = true;
              _usernameController.text = _username;
            });
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
      ],
    );
  }
}

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
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.onSurfaceMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: text.bodyMedium?.copyWith(
                      color: selected ? AppColors.onSurface : AppColors.onSurfaceMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected)
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

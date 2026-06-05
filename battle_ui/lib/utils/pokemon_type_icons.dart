import 'package:flutter/material.dart';

/// Helper class para obtener íconos representativos de cada tipo de Pokémon
class PokemonTypeIcons {
  /// Obtiene el ícono correspondiente al tipo de Pokémon
  static IconData getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return Icons.circle_outlined;
      case 'fuego':
      case 'fire':
        return Icons.local_fire_department;
      case 'agua':
      case 'water':
        return Icons.water_drop;
      case 'eléctrico':
      case 'electric':
        return Icons.flash_on;
      case 'planta':
      case 'grass':
        return Icons.grass;
      case 'hielo':
      case 'ice':
        return Icons.ac_unit;
      case 'lucha':
      case 'fighting':
        return Icons.sports_mma;
      case 'veneno':
      case 'poison':
        return Icons.science;
      case 'tierra':
      case 'ground':
        return Icons.terrain;
      case 'volador':
      case 'flying':
        return Icons.air;
      case 'psíquico':
      case 'psychic':
        return Icons.psychology;
      case 'bicho':
      case 'bug':
        return Icons.bug_report;
      case 'roca':
      case 'rock':
        return Icons.landscape;
      case 'fantasma':
      case 'ghost':
        return Icons.blur_on;
      case 'dragón':
      case 'dragon':
        return Icons.trending_up;
      case 'siniestro':
      case 'dark':
        return Icons.nightlight;
      case 'acero':
      case 'steel':
        return Icons.shield;
      case 'hada':
      case 'fairy':
        return Icons.auto_awesome;
      default:
        return Icons.help_outline;
    }
  }

  /// Obtiene el color representativo del tipo de Pokémon
  static Color getColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return const Color(0xFFA8A878);
      case 'fuego':
      case 'fire':
        return const Color(0xFFF08030);
      case 'agua':
      case 'water':
        return const Color(0xFF6890F0);
      case 'eléctrico':
      case 'electric':
        return const Color(0xFFF8D030);
      case 'planta':
      case 'grass':
        return const Color(0xFF78C850);
      case 'hielo':
      case 'ice':
        return const Color(0xFF98D8D8);
      case 'lucha':
      case 'fighting':
        return const Color(0xFFC03028);
      case 'veneno':
      case 'poison':
        return const Color(0xFFA040A0);
      case 'tierra':
      case 'ground':
        return const Color(0xFFE0C068);
      case 'volador':
      case 'flying':
        return const Color(0xFFA890F0);
      case 'psíquico':
      case 'psychic':
        return const Color(0xFFF85888);
      case 'bicho':
      case 'bug':
        return const Color(0xFFA8B820);
      case 'roca':
      case 'rock':
        return const Color(0xFFB8A038);
      case 'fantasma':
      case 'ghost':
        return const Color(0xFF705898);
      case 'dragón':
      case 'dragon':
        return const Color(0xFF7038F8);
      case 'siniestro':
      case 'dark':
        return const Color(0xFF705848);
      case 'acero':
      case 'steel':
        return const Color(0xFFB8B8D0);
      case 'hada':
      case 'fairy':
        return const Color(0xFFEE99AC);
      default:
        return Colors.grey;
    }
  }

  /// Widget helper para mostrar el ícono del tipo con su color
  static Widget buildTypeIcon(String type, {double size = 20}) {
    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: getColor(type).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        getIcon(type),
        size: size,
        color: getColor(type),
      ),
    );
  }

  /// Badge de tipo con ícono y nombre
  static Widget buildTypeBadge(String type, {double fontSize = 10}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.8,
        vertical: fontSize * 0.4,
      ),
      decoration: BoxDecoration(
        color: getColor(type),
        borderRadius: BorderRadius.circular(fontSize * 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getIcon(type),
            size: fontSize * 1.2,
            color: Colors.white,
          ),
          SizedBox(width: fontSize * 0.4),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

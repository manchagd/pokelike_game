import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Helper class para obtener íconos representativos de cada tipo de Pokémon
class PokemonTypeIcons {
  /// Obtiene la ruta del archivo SVG correspondiente al tipo de Pokémon
  static String getSvgPath(String type) {
    String name;
    switch (type.toLowerCase()) {
      case 'bicho':
      case 'bug':
        name = 'bug';
        break;
      case 'siniestro':
      case 'dark':
        name = 'dark';
        break;
      case 'dragón':
      case 'dragon':
        name = 'dragon';
        break;
      case 'eléctrico':
      case 'electric':
        name = 'electric';
        break;
      case 'hada':
      case 'fairy':
        name = 'fairy';
        break;
      case 'lucha':
      case 'fighting':
        name = 'fighting';
        break;
      case 'fuego':
      case 'fire':
        name = 'fire';
        break;
      case 'volador':
      case 'flying':
        name = 'flying';
        break;
      case 'fantasma':
      case 'ghost':
        name = 'ghost';
        break;
      case 'planta':
      case 'grass':
        name = 'grass';
        break;
      case 'tierra':
      case 'ground':
        name = 'ground';
        break;
      case 'hielo':
      case 'ice':
        name = 'ice';
        break;
      case 'normal':
        name = 'normal';
        break;
      case 'veneno':
      case 'poison':
        name = 'poison';
        break;
      case 'psíquico':
      case 'psychic':
        name = 'psychic';
        break;
      case 'roca':
      case 'rock':
        name = 'rock';
        break;
      case 'acero':
      case 'steel':
        name = 'steel';
        break;
      case 'agua':
      case 'water':
        name = 'water';
        break;
      default:
        name = 'normal';
    }
    return 'assets/icons/types/$name.svg';
  }

  /// Construye un widget de imagen SVG para el tipo dado con tamaño y color opcional.
  static Widget buildSvgIcon(String type, {double size = 20, Color? color}) {
    return SvgPicture.asset(
      getSvgPath(type),
      width: size,
      height: size,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }

  /// Obtiene el ícono correspondiente al tipo de Pokémon (como fallback de Material)
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
        return Icons.diamond; // Fallback místico
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

  /// Obtiene el color representativo del tipo de Pokémon (Paleta Generación IX / Scarlet & Violet)
  static Color getColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return const Color(0xFFA0A29F);
      case 'fuego':
      case 'fire':
        return const Color(0xFFE62829);
      case 'agua':
      case 'water':
        return const Color(0xFF2980EF);
      case 'eléctrico':
      case 'electric':
        return const Color(0xFFFAC000);
      case 'planta':
      case 'grass':
        return const Color(0xFF3FA129);
      case 'hielo':
      case 'ice':
        return const Color(0xFF3DCEF3);
      case 'lucha':
      case 'fighting':
        return const Color(0xFFC22E28);
      case 'veneno':
      case 'poison':
        return const Color(0xFF9141CB);
      case 'tierra':
      case 'ground':
        return const Color(0xFF915121);
      case 'volador':
      case 'flying':
        return const Color(0xFF81B9EF);
      case 'psíquico':
      case 'psychic':
        return const Color(0xFFEF4179);
      case 'bicho':
      case 'bug':
        return const Color(0xFF91A119);
      case 'roca':
      case 'rock':
        return const Color(0xFFAFA981);
      case 'fantasma':
      case 'ghost':
        return const Color(0xFF704170);
      case 'dragón':
      case 'dragon':
        return const Color(0xFF5060E1);
      case 'siniestro':
      case 'dark':
        return const Color(0xFF624D4E);
      case 'acero':
      case 'steel':
        return const Color(0xFF60A1B8);
      case 'hada':
      case 'fairy':
        return const Color(0xFFEF70EF);
      default:
        return Colors.grey;
    }
  }

  /// Widget helper para mostrar el ícono del tipo con su color (usando SVG)
  static Widget buildTypeIcon(String type, {double size = 20}) {
    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: getColor(type).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: buildSvgIcon(
        type,
        size: size,
        color: getColor(type),
      ),
    );
  }

  /// Badge de tipo con ícono y nombre (usando SVG)
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
          buildSvgIcon(
            type,
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

  /// Obtiene un color de texto de alto contraste para el tipo dado.
  /// Si el tema es claro, oscurece el color del tipo para mejorar el contraste.
  static Color getContrastColor(String type, BuildContext context) {
    final rawColor = getColor(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return rawColor;

    // Oscurecer el color para tema claro usando HSL
    final hsl = HSLColor.fromColor(rawColor);
    final t = type.toLowerCase();
    final isVeryLight = t == 'electric' || 
                        t == 'eléctrico' ||
                        t == 'ice' ||
                        t == 'hielo' ||
                        t == 'flying' ||
                        t == 'volador' ||
                        t == 'fairy' ||
                        t == 'hada';
    final lightnessOffset = isVeryLight ? 0.35 : 0.22;
    final darkHSL = hsl.withLightness((hsl.lightness - lightnessOffset).clamp(0.0, 0.55));
    return darkHSL.toColor();
  }
}

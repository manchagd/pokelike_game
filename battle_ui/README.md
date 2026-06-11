# Pixel Clash - Battle UI

Interfaz de usuario (UI) responsiva para el proyecto **pokelike_game**, construida con **Flutter**. Este cliente corre por fuera de Docker y se comunica (o comunicará) con el backend en tiempo real para las batallas.

## Requisitos previos

Para poder ejecutar y compilar esta aplicación de manera local, necesitas tener instalado Flutter y las herramientas específicas según tu sistema operativo.

### Requisitos generales

- **Flutter SDK**: `>= 3.41.0` (Sugerido gestionar versiones con `asdf` utilizando el plugin de Flutter).
- **Dart SDK**: `^3.8.0` (Viene incluido con el SDK de Flutter).

---

### Requisitos por sistema operativo para Desktop

#### macOS (Desktop)
- **Xcode** 15 o superior.
- **CocoaPods** instalado (`sudo gem install cocoapods` o `brew install cocoapods`). Aunque los plugins actuales son puramente Dart, es mandatorio para compilar proyectos Flutter que en el futuro requieran dependencias nativas.

#### Windows (Desktop)
- **Visual Studio 2022** con la carga de trabajo **"Desarrollo de escritorio con C++"** instalada (incluyendo MSVC v143 build tools y Windows SDK).

#### Linux (Desktop)
- Las siguientes librerías y herramientas de compilación instaladas mediante tu gestor de paquetes (ej. apt en Debian/Ubuntu):
  ```bash
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev
  ```

---

## Setup local rápido

1. **Obtener las dependencias de Flutter:**
   Desde la carpeta `battle_ui`, descarga las dependencias especificadas en el archivo `pubspec.yaml`:
   ```bash
   flutter pub get
   ```

2. **Configurar variables de entorno:**
   Copia el archivo de plantilla y ajusta la URL del WebSocket según tu entorno:
   ```bash
   cp config.json.example config.json
   ```

3. **Analizar el código (Linter):**
   Asegúrate de que no haya errores estáticos ni problemas sintácticos:
   ```bash
   flutter analyze
   ```

3. **Formatear el código:**
   Si deseas formatear de manera estandarizada todos los archivos `.dart`:
   ```bash
   flutter format .
   ```

---

## Comandos útiles de Ejecución (Run)

Para levantar la aplicación en modo desarrollo (debug) con soporte de Hot Reload, debes ejecutar pasándole el archivo de configuración del entorno usando `--dart-define-from-file`:

| Comando | Plataforma de Destino | Requisitos previos en el proyecto |
|---|---|---|
| `flutter run --dart-define-from-file=config.json -d macos` | **macOS (Nativo)** | Carpeta `macos/` creada y `config.json` configurado |
| `flutter run --dart-define-from-file=config.json -d windows` | **Windows (Nativo)** | Carpeta `windows/` creada y `config.json` configurado |
| `flutter run --dart-define-from-file=config.json -d linux` | **Linux (Nativo)** | Carpeta `linux/` creada y `config.json` configurado |
| `flutter run --dart-define-from-file=config.json -d chrome` | **Web (Navegador)** | Carpeta `web/` creada y `config.json` configurado |

> **Nota:** Si en algún momento necesitas dar soporte a Windows o Linux y no tienes los directorios correspondientes en la raíz del proyecto, puedes generarlos corriendo:
> ```bash
> flutter create --platforms=windows,linux .
> ```

---

## Compilación para Producción (Build)

Para compilar ejecutables optimizados de producción listos para distribución (Release mode):

### macOS Desktop
```bash
flutter build macos
```
El ejecutable compilado y empaquetado como App Bundle se guardará en:
`build/macos/Build/Products/Release/pixel_clash.app`

### Windows Desktop
```bash
flutter build windows
```
El ejecutable `.exe` junto a todas las librerías dinámicas necesarias se guardará en:
`build/windows/x64/runner/Release/`

### Linux Desktop
```bash
flutter build linux
```
El binario ejecutable y sus recursos se guardarán en:
`build/linux/x64/release/bundle/`

### Web
```bash
flutter build web --web-renderer canvaskit
```
Los archivos estáticos optimizados listos para desplegar en cualquier hosting estático se guardarán en:
`build/web/`

---

## Estructura del proyecto

```
battle_ui/
├── android/          # Código nativo para Android
├── ios/              # Código nativo para iOS
├── macos/            # Código nativo para macOS Desktop
├── web/              # Archivos de soporte web (index.html, etc.)
│
├── assets/           # Recursos del juego (imágenes, iconos, tipografías)
│
├── lib/
│   ├── main.dart     # Entrypoint del cliente Flutter
│   ├── nav.dart      # Configuración de rutas declarativas (GoRouter)
│   ├── theme.dart    # Sistema de diseño (paleta de colores HSL, tipografía, espaciados)
│   │
│   ├── pages/        # Pantallas de la aplicación
│   │   ├── home_page.dart           # Dashboard principal con transiciones
│   │   ├── matches_view.dart        # Selección de equipo, historial y emparejamiento
│   │   ├── team_builder_view.dart   # Constructor y visualizador de equipos
│   │   └── battle_view.dart         # Arena de combate interactiva en vivo
│   │
│   ├── widgets/      # Componentes UI encapsulados
│   │   └── sidebar.dart             # Barra de navegación lateral persistente
│   │
│   └── utils/        # Funciones helpers o estáticas
│       ├── pokemon_type_icons.dart  # Iconografía y colorización de tipos de monstruos
│       ├── battle_socket_service.dart # Servicio de conexión a WebSockets de Phoenix
│       └── config.dart              # Carga de configuración del entorno (config.json)
│
├── pubspec.yaml      # Dependencias del proyecto y assets declarados
└── README.md         # Este archivo
```

---

## Flujo de Pantalla de Combate (battle_view.dart)

La pantalla del combate en vivo en Flutter gestiona la experiencia del jugador en tiempo real adaptando la interfaz según la fase actual del combate transmitida por el servidor de Phoenix.

### Gestión de Fases (`BattlePhase`)

Para evitar strings mágicas y garantizar la seguridad de tipos, la interfaz utiliza el enum `BattlePhase` con getters semánticos que encapsulan la visibilidad de los componentes:

* **`BattlePhase.waitingPlayers`** (`isWaitingPlayers`): El combate se encuentra en el lobby esperando a que se conecten todos los entrenadores requeridos (ej. 2 para 1v1, 4 para 2v2). La interfaz renderiza un panel de "Sala de Espera" que muestra el progreso de conexión (`connected_players / expected_players`) y las tarjetas de perfil de los jugadores conectados en tiempo real.
* **`BattlePhase.waitingActions`** (`isWaitingActions`): El combate está activo y listo para comandos. La UI despliega la arena de combate tridimensional simulada con los monstruos activos de ambos bandos, la barra de selección de movimientos, y un contador de tiempo regresivo sincronizado con el timestamp UNIX `turn_expires_at` enviado por el servidor.
* **`BattlePhase.resolving`**: Las acciones del turno se están procesando o simulando en el backend.
* **`BattlePhase.finished`**: El combate ha concluido formalmente.

### Mecánica de Rendición (Forfeit)

* **Botón "Rendirse"**: Incorporado en las acciones del `AppBar` de la arena. Está habilitado solo cuando el combate está activo o en lobby.
* **Diálogo de Confirmación**: Al presionarlo, despliega un diálogo de confirmación modal (`_showSurrenderConfirmation`) para evitar abandonos involuntarios.
* **Envío al Servidor**: Al confirmar la rendición, el cliente despacha un mensaje de evento `"action"` con payload `"action": "forfeit"` por el canal WebSocket de la batalla.
* **Cierre de Sesión**: Cuando el canal difunde el evento de cierre `"battle_ended"`, el cliente intercepta la desconexión, muestra un diálogo final con el motivo del término (ej. *"El entrenador X se ha retirado. Combate finalizado."*), y redirige de forma segura al usuario de regreso a la pantalla de inicio (`HomePage`).


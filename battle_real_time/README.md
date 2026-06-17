# Battle Real Time

Servicio de comunicación en tiempo real para el proyecto **pokelike_game**. App Elixir/Phoenix que actúa como puente entre los clientes (WebSocket) y el motor de batalla (RabbitMQ).

## Requisitos

- **Elixir** 1.18+
- **Erlang/OTP** 26+
- **RabbitMQ** 4.0+ (Misma versión que el contenedor de Docker)

> También puedes correr todo con **Docker** sin instalar nada localmente.

## Setup local

```bash
# 1. Copia las variables de entorno
cp .env.example .env

# 2. Instala dependencias
mix setup

# 3. Arranca el servidor Phoenix
mix phx.server
```

El servidor estará disponible en [`localhost:4000`](http://localhost:4000).

## Setup con Docker (desde la raíz del proyecto)

```bash
# Levantar RabbitMQ y el servicio
docker compose up -d rabbitmq battle_real_time

# Ver los logs
docker compose logs -f battle_real_time
```

## Arquitectura

### Flujo de mensajes

```
┌─────────────┐    WebSocket     ┌──────────────────┐     RabbitMQ      ┌───────────────┐
│   Cliente   │ ───────────────> │  battle_real_time │ ───────────────> │ battle_engine │
│  (browser)  │    battle:42     │                   │  battle_actions   │               │
│             │                  │   BattleChannel   │                  │               │
│             │ <─────────────── │   AMQP.Consumer   │ <─────────────── │               │
│             │  "battle_event"  │                   │  battle_events    │               │
└─────────────┘                  └──────────────────┘                   └───────────────┘
```

1. El **cliente** se conecta vía WebSocket al canal `battle:<battle_id>`
2. Cuando el cliente envía una acción, `BattleChannel` la publica en la cola `battle_actions` (RabbitMQ)
3. `battle_engine` (Ruby) consume de `battle_actions`, procesa la lógica de batalla y publica el resultado en `battle_events`
4. `AMQP.Consumer` recibe el evento desde `battle_events` y lo retransmite vía PubSub al `BattleChannel`
5. `BattleChannel` pushea el evento al cliente por WebSocket

### Árbol de supervisión (OTP)

```
BattleRealTime.Supervisor (one_for_one)
├── BattleRealTimeWeb.Telemetry
├── DNSCluster
├── Phoenix.PubSub (BattleRealTime.PubSub)
├── BattleRealTime.AMQP.Connection     ← conexión compartida a RabbitMQ
├── BattleRealTime.AMQP.Consumer       ← escucha cola "battle_events"
├── BattleRealTime.AMQP.Publisher      ← publica en cola "battle_actions"
└── BattleRealTimeWeb.Endpoint         ← servidor HTTP/WebSocket
```

### Colas RabbitMQ

| Cola | Dirección | Descripción |
|------|-----------|-------------|
| `player_actions` | real_time → engine | Acciones de entrenadores (registro, etc.) |
| `player_events` | engine → real_time | Eventos de perfil e historial del entrenador |
| `battle_actions` | real_time → engine | Acciones del jugador en combate (attack, switch, etc.) |
| `battle_events` | engine → real_time | Eventos procesados de batalla (fases, estado del combate, logs) |

## Mix Tasks disponibles

Todas las tareas se ejecutan con `mix <tarea>`. Desde Docker: `docker compose run --rm battle_real_time mix <tarea>`.

| Tarea Mix | Descripción |
|-----------|-------------|
| `mix setup` | Instala dependencias |
| `mix phx.server` | Arranca el servidor Phoenix |
| `mix amqp.publish.attack` | Publica un mensaje de prueba `attack` en la cola `battle_actions` |
| `mix amqp.publish.change` | Publica un mensaje de prueba `change` en la cola `battle_actions` |

### Mensajes de prueba

Los Mix Tasks permiten inyectar mensajes con estructura real en RabbitMQ para testing. Todos los campos tienen valores por defecto y se pueden sobreescribir con `key=value`.

#### `mix amqp.publish.attack`

```bash
# Con valores por defecto
mix amqp.publish.attack

# Con valores específicos
mix amqp.publish.attack battle_id=99 trainer_id=2 move_id=10 target_positions=0,1
```

Estructura del mensaje:
```json
{
  "event": "attack",
  "payload": {
    "battle_id": "42",
    "trainer_id": "1",
    "move_id": "85",
    "target_positions": ["1", "2"],
    "timestamp": "2026-06-02T15:00:00Z"
  }
}
```

#### `mix amqp.publish.change`

```bash
# Con valores por defecto
mix amqp.publish.change

# Con valores específicos
mix amqp.publish.change battle_id=99 trainer_id=2 pokemon_in_id=6 pokemon_out_id=4
```

Estructura del mensaje:
```json
{
  "event": "change",
  "payload": {
    "battle_id": "42",
    "trainer_id": "1",
    "pokemon_in_id": "9",
    "pokemon_out_id": "25",
    "timestamp": "2026-06-02T15:00:00Z"
  }
}
```

## Variables de entorno

| Variable | Default | Descripción |
|----------|---------|-------------|
| `RABBITMQ_URL` | `amqp://guest:admin@localhost:5672` | URL de conexión RabbitMQ |
| `PORT` | `4000` | Puerto del servidor Phoenix |
| `SECRET_KEY_BASE` | (requerido en prod) | Clave para firmar cookies y secrets. Ver [Generación de SECRET_KEY_BASE](#generación-de-secret_key_base) |
| `PHX_SERVER` | `false` | Habilita el servidor HTTP (activado en el Dockerfile) |
| `PHX_HOST` | `example.com` | Host de producción (solo entorno prod) |
| `DNS_CLUSTER_QUERY` | - | Consulta para DNS Cluster (solo entorno prod) |

### Generación de SECRET_KEY_BASE

Para generar una clave segura para `SECRET_KEY_BASE`, Phoenix incluye una tarea Mix que genera una clave aleatoria criptográficamente segura:

```bash
mix phx.gen.secret [length]
```

## Mapeo de Puertos y Versiones (Local vs Docker)

Para mantener la consistencia entre ejecutar localmente (en tu máquina) o usando Docker Compose, considera la correspondencia de configuraciones:

| Componente / Servicio | Entorno Local (Host) | Entorno Docker | Versión y Detalles (según docker-compose.yml) |
|---|---|---|---|
| **Servidor Phoenix** | `localhost:4000` | Mapeo puerto `4000:4000` | Puerto por defecto: `4000`. Env variable: `PORT` |
| **RabbitMQ Broker** | `localhost:5672` | `rabbitmq:5672` | Imagen: `rabbitmq:4.0-management-alpine`<br>Credenciales por defecto: `guest:admin` |
| **RabbitMQ Management UI** | `localhost:15672` | `rabbitmq:15672` | Mapeado al puerto `15672` local para inspección visual |
| **Elixir / Erlang** | Instalar local: Elixir `1.18.4`, Erlang `26.2.5` | Versión container: Elixir `1.18.4`, Erlang `26.2.5` | Imagen base: `hexpm/elixir:1.18.4-erlang-26.2.5.13-alpine-3.21.3` |

## Estructura del proyecto

```
battle_real_time/
├── mix.exs                     # Dependencias y configuración del proyecto
├── Dockerfile                  # Multi-stage: dev (con mix) + prod (release)
├── .env.example                # Variables de entorno (ejemplo)
├── README.md                   # Este archivo
│
├── config/
│   ├── config.exs              # Configuración base (todas las envs)
│   ├── dev.exs                 # Configuración para desarrollo
│   ├── prod.exs                # Configuración para producción
│   ├── test.exs                # Configuración para tests
│   └── runtime.exs             # Configuración en tiempo de ejecución (ENV vars)
│
 ├── lib/
│   ├── battle_real_time/
│   │   ├── application.ex      # Árbol de supervisión OTP
│   │   ├── battle_session.ex   # GenServer que maneja el ciclo de vida del combate, lobby y turnos
│   │   ├── amqp/
│   │   │   ├── connection.ex   # Conexión compartida a RabbitMQ (GenServer)
│   │   │   ├── consumer.ex     # Macro behavior base para consumidores AMQP
│   │   │   ├── publisher.ex    # Macro behavior base para publicadores AMQP
│   │   │   ├── consumers/      # Consumidores específicos de colas RabbitMQ
│   │   │   │   ├── battle_events_consumer.ex
│   │   │   │   └── player_events_consumer.ex
│   │   │   └── publishers/     # Publicadores específicos de colas RabbitMQ
│   │   │       ├── battle_actions_publisher.ex
│   │   │       └── player_actions_publisher.ex
│   │   │
│   │   └── contracts/          # Contratos de validación de esquemas con Ecto
│   │       ├── consumers/      # Esquemas para validar payloads entrantes
│   │       │   └── player_events/
│   │       │       └── info_contract.ex
│   │       └── publishers/     # Esquemas para validar payloads salientes
│   │           ├── battle_actions/
│   │           │   ├── terminate_battle_contract.ex  # Valida la orden de finalización del combate (forfeit)
│   │           │   └── turn_actions_contract.ex      # Valida el envío consolidado de acciones del turno
│   │           └── player_actions/
│   │               └── register_contract.ex
│   │
│   ├── battle_real_time_web/
│   │   ├── endpoint.ex         # Endpoint HTTP/WebSocket
│   │   ├── router.ex           # Rutas HTTP
│   │   ├── user_socket.ex      # Socket WebSocket (transportes)
│   │   └── channels/
│   │       ├── battle_channel.ex  # Canal "battle:<id>" (join, actions, events)
│   │       └── player_channel.ex  # Canal "player:<identifier>" (registro, perfil)
│   │
│   └── mix/
│       └── tasks/
│           ├── amqp_publish_helpers.ex       # Helpers compartidos para Mix Tasks
│           ├── amqp.publish.attack.ex        # mix amqp.publish.attack
│           └── amqp.publish.change.ex        # mix amqp.publish.change
│
└── test/                       # Tests
```

## Ciclo de Vida y Gestión de la Batalla (BattleSession)

La lógica de estado de cada combate activo está encapsulada en un proceso `GenServer` independiente registrado bajo el alias `BattleRealTime.BattleSession`. Este proceso se inicia dinámicamente bajo `BattleRealTime.BattleSupervisor` cuando el primer jugador se conecta al canal de la batalla.

### Máquina de Estados y Fases

El GenServer opera a través de las siguientes fases utilizando un diseño con átomos seguros para el manejo del estado:

```mermaid
stateDiagram-v2
    [*] --> waiting_players : start_link
    waiting_players --> setting_up : Todos los jugadores conectados
    setting_up --> waiting_actions : Todos los jugadores seleccionan líder
    waiting_actions --> waiting_actions : Turno completado / Siguiente turno
    waiting_actions --> finished : Un jugador se rinde (forfeit) o agota tiempo
    finished --> [*] : GenServer se apaga (:normal)
```

1. **Lobby / Sala de Espera (`:waiting_players`)**:
   * Al crearse, la batalla inicia en esta fase con un formato de combate predefinido (ej. `"1v1"`, `"2v2"`).
   * Determina cuántos entrenadores deben unirse (`"1v1"` requiere 2, `"2v2"` requiere 4).
   * Almacena en memoria (`MapSet`) los identificadores y nombres de usuario de los jugadores a medida que se unen al canal WebSocket.
   * Al completarse la capacidad de la sala, cancela cualquier temporizador inactivo y pasa a la fase `:waiting_actions`.

2. **Acciones del Turno (`:waiting_actions`)**:
   * Espera que todos los jugadores registrados envíen su acción a través de WebSocket (`handle_in("action", ...)`).
   * Inicia un temporizador de gracia de 2 minutos (`120` segundos) al inicio de cada turno.
   * Una vez recibidos todos los comandos requeridos, cancela el temporizador de gracia, unifica las acciones en una sola lista validada (`turn_actions`), la publica en RabbitMQ (`battle_actions` queue), incrementa el número de turno, reinicia el temporizador de gracia y notifica a los clientes vía WebSocket.

3. **Rendición y Término (`forfeit`)**:
   * Un jugador puede enviar en cualquier momento el evento `"forfeit"`.
   * Esto desencadena una terminación limpia de la sesión de batalla:
     * Difunde el evento `"battle_ended"` al canal WebSocket con el motivo/motivo del forfeit.
     * Envía la orden `"terminate_battle"` (validada mediante el esquema `TerminateBattleContract`) a la cola `battle_actions` en RabbitMQ.
     * Apaga el proceso GenServer de manera ordenada retornando `{:stop, :normal, :ok, state}`.

---

## Quick Start (Docker)

Desde la raíz del proyecto (`pokelike_game/`):

```bash
# 1. Levantar RabbitMQ y el servicio
docker compose up -d rabbitmq battle_real_time

# 2. Ver los logs — deberías ver:
#    [AMQP.Connection] Connected to RabbitMQ
#    [AMQP.Consumer] Subscribed to queue 'battle_events'
#    [AMQP.Publisher] Ready to publish to queue 'battle_actions'
docker compose logs -f battle_real_time

# 3. En otra terminal, publicar un mensaje de prueba
docker compose run --rm battle_real_time mix amqp.publish.attack

# 4. En los logs verás:
#    [AMQP.Publisher] Published action 'attack' to 'battle_actions'
```

### Parar todo

```bash
docker compose down           # para los containers
docker compose down -v        # para los containers Y borra los volúmenes
```

### RabbitMQ Management UI

```bash
open http://localhost:15672    # user: guest / pass: admin
```

Para inspeccionar el contenido de los mensajes:
1. Ve a **Queues and Streams**
2. Click en la cola (ej. `battle_actions`)
3. Sección **Get messages** → Ack mode: `Nack message requeue true`
4. Click **Get Message(s)** para ver el payload JSON

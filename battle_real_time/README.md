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
| `battle_actions` | real_time → engine | Acciones del jugador (attack, change, etc.) |
| `battle_events` | engine → real_time | Eventos procesados (resultado de ataques, fin de batalla, etc.) |

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

Para generar una clave segura para `SECRET_KEY_BASE`, Phoenix incluye una tarea Mix que genera una cadena aleatoria criptográficamente segura. Ejecuta el siguiente comando en tu terminal:

```bash
mix phx.gen.secret [length]
```

**Detalles del comando y opciones:**
- **Sin argumentos**: Por defecto, genera una clave aleatoria de **64 caracteres**.
- **`[length]`**: Opcionalmente, puedes pasar un entero como argumento para cambiar la longitud de la clave generada.
  - *Restricción*: La longitud mínima permitida es **32**. Si se ingresa un número menor, el comando devolverá un error de validación.
- **Ejemplos**:
  ```bash
  # Genera una clave con la longitud por defecto (64 caracteres)
  mix phx.gen.secret

  # Genera una clave de 32 caracteres (mínimo permitido)
  mix phx.gen.secret 32

  # Genera una clave de 128 caracteres
  mix phx.gen.secret 128
  ```
Una vez generada la clave, cópiala y asígnala a la variable `SECRET_KEY_BASE` en tu archivo `.env`.

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
│   │   └── amqp/
│   │       ├── connection.ex   # Conexión compartida a RabbitMQ (GenServer)
│   │       ├── consumer.ex     # Consume de "battle_events", broadcast vía PubSub
│   │       └── publisher.ex    # Publica acciones en "battle_actions"
│   │
│   ├── battle_real_time_web/
│   │   ├── endpoint.ex         # Endpoint HTTP/WebSocket
│   │   ├── router.ex           # Rutas HTTP
│   │   ├── user_socket.ex      # Socket WebSocket (transportes)
│   │   └── channels/
│   │       └── battle_channel.ex  # Canal "battle:<id>" (join, actions, events)
│   │
│   └── mix/
│       └── tasks/
│           ├── amqp_publish_helpers.ex       # Helpers compartidos para Mix Tasks
│           ├── amqp.publish.attack.ex        # mix amqp.publish.attack
│           └── amqp.publish.change.ex        # mix amqp.publish.change
│
└── test/                       # Tests
```

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

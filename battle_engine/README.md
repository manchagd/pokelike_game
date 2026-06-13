# Battle Engine

Motor de batalla para el proyecto **pokelike_game**. App Ruby standalone (sin Rails) que usa ActiveRecord, PostgreSQL y RabbitMQ.

## Requisitos

- **Ruby** 4.0.1
- **PostgreSQL** 16+
- **RabbitMQ** 4.0+ (Misma versión que el contenedor de Docker)
- **Bundler** (`gem install bundler`)

> También puedes correr todo con **Docker** sin instalar nada localmente.

## Setup local

```bash
# 1. Copia las variables de entorno
cp .env.example .env

# 2. Instala dependencias
bundle install

# 3. Crea la base de datos, corre migraciones y seeds
bundle exec rake db:setup
```

## Setup con Docker (desde la raíz del proyecto)

```bash
# Levanta PostgreSQL y RabbitMQ
docker compose up -d postgres rabbitmq

# Crea la base de datos
docker compose run battle_engine bundle exec rake db:create

# Corre migraciones
docker compose run battle_engine bundle exec rake db:migrate

# Seeds
docker compose run battle_engine bundle exec rake db:seed

# O todo junto:
docker compose run battle_engine bundle exec rake db:setup
```

## Calidad de Código (RuboCop)

El motor utiliza **RuboCop** (con el plugin de performance) para mantener el estilo de código limpio y consistente. Las reglas personalizadas están configuradas en [.rubocop.yml](file:///Users/manchagd/pokelike_game/battle_engine/.rubocop.yml).

### Ejecutar localmente

```bash
# Inspeccionar el código en busca de ofensas
bundle exec rubocop

# Correr autocorreciones seguras automáticamente
bundle exec rubocop -a

# Correr todas las autocorreciones (incluyendo las potencialmente inseguras)
bundle exec rubocop -A
```

### Ejecutar con Docker

```bash
# Inspeccionar el código
docker compose run --rm battle_engine bundle exec rubocop

# Correr autocorreciones seguras
docker compose run --rm battle_engine bundle exec rubocop -a
```

## Tareas Rake disponibles

Todas las utilidades están definidas en el `Rakefile` y se ejecutan usando `bundle exec rake <tarea>`:

| Tarea Rake | Descripción |
|---|---|
| `db:create` | Crea la base de datos (`battle_engine_<APP_ENV>`) |
| `db:drop` | Elimina la base de datos |
| `db:create_migration[name]` | Genera una nueva migración con timestamp (ej. `bundle exec rake db:create_migration[create_users]`) |
| `db:migrate` | Ejecuta migraciones pendientes y actualiza `db/schema.rb` |
| `db:rollback[steps]` | Revierte la(s) última(s) migración(es) y actualiza `db/schema.rb`. Ej: `bundle exec rake db:rollback[3]` (default: 1) |
| `db:seed` | Ejecuta `db/seeds.rb` (datos iniciales de movimientos) |
| `db:seed[file]` | Ejecuta un seed específico de `db/seed/<file>_seed.rb`. Ej: `bundle exec rake "db:seed[pokemon_template]"` |
| `db:seed[file,true]` | Ejecuta el seed ignorando el caché local y forzando un nuevo fetch desde la API. Ej: `bundle exec rake "db:seed[pokemon_template,true]"` |
| `db:setup` | Ejecuta create + migrate + seed en secuencia |
| `console` | Abre una sesión interactiva **Pry** con el entorno completo cargado |
| `rabbitmq:publish_sample` | Publica un mensaje de prueba en la cola `battle_events` de RabbitMQ |
| `rabbitmq:publish_player_event` | Publica un mensaje de prueba (`info`) en la cola `player_events` de RabbitMQ |

## Arquitectura de Boot y Ejecución

El flujo se divide en dos scripts para permitir que las utilidades y consolas carguen el entorno sin lanzar el consumer:

```
boot.rb (Carga de entorno y conexiones)
  ├── dotenv/load              (carga .env si existe)
  ├── config/environment.rb
  │     ├── app_config.rb      (lee ENV vars)
  │     ├── logger.rb          (stdout + archivo log)
  │     ├── database.rb        (ActiveRecord → PostgreSQL)
  │     ├── rabbitmq.rb        (Bunny → RabbitMQ)
  │     └── Zeitwerk           (autoload de app/)
  ├── Database.connect!
  └── RabbitMQ.connect!

start.rb (Entrypoint de ejecución del servicio)
  ├── boot.rb                  (carga y conecta)
  ├── trap SIGINT / SIGTERM    (graceful shutdown)
  └── BattleEventsConsumer.start  ← se queda vivo escuchando
```

1. **`boot.rb`** — Entry point de inicialización. Carga variables de entorno, carga los módulos de configuración, inicializa Zeitwerk para autoloading, y abre las conexiones a la base de datos y a RabbitMQ. Es requerido por todos los scripts.
2. **`start.rb`** — Script de arranque del servicio. Requiere `boot.rb`, define manejadores de señales para un apagado limpio (graceful shutdown) y arranca el loop del consumer.
3. **`config/app_config.rb`** — Módulo que lee variables de entorno con valores por defecto.
4. **`config/logger.rb`** — Logger dual: escribe a `STDOUT` y a `log/<APP_ENV>.log`.
5. **`config/database.rb`** — Establece la conexión ActiveRecord con PostgreSQL.
6. **`config/rabbitmq.rb`** — Maneja la conexión Bunny (connect/disconnect/channel).
7. **`config/environment.rb`** — Orquesta la carga: requiere los módulos anteriores y configura Zeitwerk para autoload de `app/`.
8. **`app/consumers/battle_events_consumer.rb`** — Consumer que escucha la cola `battle_events` y loggea los mensajes recibidos.

## Validación de Esquemas (Contratos)

El motor utiliza `dry-validation` para garantizar la integridad de los mensajes intercambiados con otros sistemas:
- **Inbound (Entrante)**: El `BaseConsumer` busca un contrato en `app/contracts/consumers/<event_name>_contract.rb`. Si existe, valida el payload recibido antes de invocar al servicio correspondiente.
- **Outbound (Saliente)**: El `BasePublisher` busca un contrato en `app/contracts/publishers/<event_name>_contract.rb`. Si existe, valida el payload generado antes de enviarlo a RabbitMQ. Si falla, escribe un error en el log y descarta la publicación para evitar enviar datos corruptos a la red.

## Integración de Mensajes de Combate (RabbitMQ)

El motor de batalla interactúa con el servidor de tiempo real mediante mensajería en las siguientes colas:

### Eventos Consumidos de `battle_actions` (Inbound)

* **`turn_actions`**: Enviado por el servidor de tiempo real cuando se han recolectado todas las acciones del turno actual de los jugadores.
  * **Acción**: El motor debe calcular los resultados del turno (velocidades de ataque, daños, fallos, cambios de monstruos, KO) y persistirlos.
  * **Payload esperado**:
    ```json
    {
      "event": "turn_actions",
      "payload": {
        "battle_id": "482-913",
        "turn": 1,
        "actions": [
          {
            "action": "attack",
            "player_id": "101",
            "move_id": "thunderbolt",
            "targets": ["enemy_pelipper"]
          },
          {
            "action": "switch",
            "player_id": "102",
            "monster_id": "swampert"
          }
        ]
      }
    }
    ```

* **`terminate_battle`**: Orden de cancelación/finalización forzada o por rendición de un combate activo.
  * **Acción**: El motor debe registrar la finalización del combate en base de datos, calcular quién es el ganador/perdedor (si aplica) para actualizar el historial de perfil del entrenador, y liberar recursos.
  * **Payload esperado**:
    ```json
    {
      "event": "terminate_battle",
      "payload": {
        "battle_id": "482-913",
        "reason": "El jugador AshKetchum se rinde."
      }
    }
    ```

## Seeds

El proyecto tiene dos niveles de seeds:

### `db/seeds.rb` — Seeds globales
Carga datos estáticos de **movimientos** (`Move`). Se ejecuta con:

```bash
bundle exec rake db:seed
```

### `db/seed/` — Seeds individuales
Archivos de seed especializados que se pueden ejecutar de forma independiente.

#### `pokemon_template` — Plantillas de Pokémon (vía PokeAPI)

Consulta la [PokeAPI](https://pokeapi.co/) para cargar los primeros ~1,000 Pokémon (IDs 1–9999) como `PokemonTemplate` en la base de datos. Guarda los siguientes campos por cada Pokémon:

| Campo | Tipo | Descripción |
|---|---|---|
| `name` | string | Nombre formateado (ej. `Mr Mime`) |
| `types` | string[] | Tipos válidos según `Types::LIST` |
| `stats` | jsonb | `{ hp, atk, def, sp_atk, sp_def, spd }` |
| `front_sprite` | string | URL del sprite frontal (ver lógica de prioridad) |
| `back_sprite` | string | URL del sprite trasero (ver lógica de prioridad) |
| `pokeapi_id` | integer | ID único asignado por la PokeAPI |

> **Nota sobre `moves` en la caché local:**
> El archivo de caché local `local_data/pokemon.json` almacena además una clave `"moves"` que contiene un arreglo de enteros con los IDs de PokeAPI de todos los movimientos que el Pokémon puede aprender (filtrados para no ser mayores a `10000`). Este arreglo no se guarda en la base de datos por el momento.

**Lógica de sprites (prioridad):**

```
sprites.other.showdown.front_default  →  front_sprite (fuente primaria)
  ↓ fallback si no existe
sprites.front_default                 →  front_sprite

sprites.other.showdown.back_default   →  back_sprite  (fuente primaria)
  ↓ fallback si no existe
sprites.back_default                  →  back_sprite
```

**Caché local (`local_data/pokemon.json`):**

Para evitar consultar la API en cada ejecución (que tarda varios minutos), el seed guarda los resultados en `local_data/pokemon.json` y lo usa automáticamente si existe.

```bash
# Uso normal — carga desde caché local si existe
bundle exec rake "db:seed[pokemon_template]"

# Forzar re-fetch desde la API (ignora el caché)
# Necesario cuando el schema del JSON cambia (nuevos campos, etc.)
bundle exec rake "db:seed[pokemon_template,true]"
```

> **Nota:** El archivo `local_data/pokemon.json` está en `.gitignore`. Si no existe en tu entorno local, el seed lo generará automáticamente consultando la API.

#### `move` — Movimientos (vía PokeAPI)

Consulta la [PokeAPI](https://pokeapi.co/) para cargar los primeros ~900 moves (IDs 1–9999) como `Move` en la base de datos. Guarda los siguientes campos:

| Campo | Tipo | Descripción |
|---|---|---|
| `name` | string | Nombre formateado (ej. `Swords Dance`) |
| `type` | string | Tipo Pokémon del move (ej. `Normal`, `Fire`) |
| `secondary_type` | string | Solo `"Flying"` para Flying Press (ID 560); `null` en los demás |
| `category` | string | `"Physical"`, `"Special"` o `"Status"` |
| `handler` | string | Categoría de comportamiento del move (ver tabla) |
| `pp` | integer | Puntos de poder |
| `power` | integer | Potencia base (`null` si no aplica) |
| `priority` | integer | Prioridad de turno |
| `accuracy` | integer | Precisión (`null` si el move no puede fallar) |
| `meta` | jsonb | Objeto de metadatos (ver estructura) |
| `pokeapi_id` | integer | ID único asignado por la PokeAPI |

**Estructura del campo `meta`:**

```json
{
  "ailment": { "name": "paralysis", "chance": 10 },
  "crit_rate": 0,
  "flinch_chance": 0,
  "drain": 0,
  "healing": 0,
  "max_hits": null,
  "min_hits": null,
  "max_turns": null,
  "min_turns": null,
  "stat_changes": [
    { "stat": "atk", "change": 2 }
  ]
}
```

**Columna `handler` — 14 valores posibles:**

| Valor | Descripción |
|---|---|
| `damage` | Solo daño, sin efectos adicionales |
| `ailment` | Aplica una condición (burn, paralysis, sleep...) |
| `net-good-stats` | Sube/baja stats |
| `heal` | Recupera HP |
| `damage-ailment` | Daño + condición |
| `swagger` | Sube stat del rival y lo confunde |
| `damage-lower` | Daño + baja stat del rival |
| `damage-raise` | Daño + sube stat propio |
| `damage-heal` | Daño + recupera HP |
| `ohko` | One-hit KO |
| `whole-field-effect` | Efecto global (lluvia, sol...) |
| `field-effect` | Efecto de campo propio (spikes, reflect...) |
| `force-switch` | Fuerza cambio de Pokémon |
| `unique` | Lógica completamente custom — requiere implementación en el engine |

> El campo `handler` es el entry point para la lógica del engine. El developer puede usarlo para STI (`self.inheritance_column = :handler`) o para un sistema de dispatch por handlers.

**Caché local (`local_data/moves.json`):**

```bash
# Uso normal — carga desde caché local si existe
bundle exec rake "db:seed[move]"

# Forzar re-fetch desde la API (ignora el caché)
bundle exec rake "db:seed[move,true]"
```

> **Nota:** El archivo `local_data/moves.json` está en `.gitignore`. Si no existe, el seed lo generará automáticamente.

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `APP_ENV` | `development` | Entorno de la app |
| `DATABASE_URL` | `postgres://postgres:admin@localhost:5432/battle_engine_development` | URL de conexión PostgreSQL |
| `RABBITMQ_URL` | `amqp://guest:admin@localhost:5672` | URL de conexión RabbitMQ |
| `LOG_LEVEL` | `debug` | Nivel de log (`debug`, `info`, `warn`, `error`, `fatal`) |

## Mapeo de Puertos y Versiones (Local vs Docker)

Para mantener la consistencia entre ejecutar localmente (en tu máquina) o usando Docker Compose, considera la correspondencia de configuraciones:

| Componente / Servicio | Entorno Local (Host) | Entorno Docker | Versión y Detalles (según docker-compose.yml) |
|---|---|---|---|
| **Base de Datos (PostgreSQL)** | `localhost:5432` | `postgres:5432` | Imagen: `postgres:16-alpine`<br>Credenciales: `postgres:admin`<br>Base de datos: `battle_engine_development` |
| **RabbitMQ Broker** | `localhost:5672` | `rabbitmq:5672` | Imagen: `rabbitmq:4.0-management-alpine`<br>Credenciales por defecto: `guest:admin` |
| **RabbitMQ Management UI** | `localhost:15672` | `rabbitmq:15672` | Mapeado al puerto `15672` local para inspección visual |
| **Intérprete de Ruby** | Ruby `4.0.1` local | Ruby `4.0.1` container | Imagen: `ruby:4.0.1-alpine` con soporte Zeitwerk |


## Estructura del proyecto

```
battle_engine/
├── Gemfile              # Dependencias Ruby
├── Dockerfile           # Imagen Docker (ejecuta start.rb)
├── .env.example         # Variables de entorno (ejemplo)
├── boot.rb              # Inicialización y conexiones
├── start.rb             # Ejecución (arranca el consumer)
├── README.md            # Este archivo
│
├── config/
│   ├── environment.rb   # Orquestador de carga
│   ├── app_config.rb    # Lectura de ENV
│   ├── database.rb      # Conexión PostgreSQL
│   ├── rabbitmq.rb      # Conexión RabbitMQ
│   └── logger.rb        # Logger dual
│
├── app/
│   ├── consumers/       # Consumers de colas de RabbitMQ (Inbound)
│   ├── contracts/       # Validación de esquemas con dry-validation
│   │   ├── consumers/   # Contratos para mensajes entrantes (Inbound)
│   │   └── publishers/  # Contratos para mensajes salientes (Outbound)
│   ├── publishers/      # Publishers para enviar a colas RabbitMQ (Outbound)
│   ├── services/        # Servicios de procesamiento de eventos (Handlers)
│   ├── messages/        # Estructura y payloads de eventos salientes
│   └── models/          # Modelos de datos ActiveRecord
│
├── db/
│   ├── schema.rb        # Esquema ActiveRecord (auto-generado)
│   ├── migrate/         # Migraciones de base de datos
│   ├── seeds.rb         # Seeds globales (movimientos)
│   └── seed/
│       └── pokemon_template_seed.rb  # Seed de plantillas Pokémon (PokeAPI)
│
├── local_data/
│   └── pokemon.json     # Caché local del seed de Pokémon (ignorado por git)
│
├── Rakefile             # Utilidades CLI centralizadas (Rake tasks)
│
└── log/                 # Archivos de log (ignorados por git)
```

## Quick Start (Docker)

Desde la raíz del proyecto (`pokelike_game/`):

```bash
# 1. Levantar PostgreSQL y RabbitMQ
docker compose up -d postgres rabbitmq

# 2. Crear la base de datos y correr migraciones
docker compose run --rm battle_engine bundle exec rake db:setup

# 3. Levantar battle_engine (se queda escuchando en la cola battle_events)
docker compose up -d battle_engine

# 4. Ver los logs — deberías ver "Listening on queue 'battle_events'..."
docker compose logs -f battle_engine

# 5. En otra terminal, publicar un mensaje de prueba
docker compose exec battle_engine bundle exec rake rabbitmq:publish_sample

# 6. En los logs verás:
#    [Consumer] Received event: battle_started
#    [Consumer] Payload: {trainer_id: 1, opponent_id: 2, ...}
```

### Parar todo

```bash
docker compose down           # para los containers
docker compose down -v        # para los containers Y borra los volúmenes (DB + RabbitMQ)
```

### RabbitMQ Management UI

```bash
open http://localhost:15672    # user: guest / pass: admin
```


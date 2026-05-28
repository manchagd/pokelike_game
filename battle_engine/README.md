# Battle Engine

Motor de batalla para el proyecto **pokelike_game**. App Ruby standalone (sin Rails) que usa ActiveRecord, PostgreSQL y RabbitMQ.

## Requisitos

- **Ruby** 4.0.1
- **PostgreSQL** 16+
- **RabbitMQ** 3+
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

## Tareas Rake disponibles

Todas las utilidades están definidas en el `Rakefile` y se ejecutan usando `bundle exec rake <tarea>`:

| Tarea Rake | Descripción |
|---|---|
| `db:create` | Crea la base de datos (`battle_engine_<APP_ENV>`) |
| `db:drop` | Elimina la base de datos |
| `db:create_migration[name]` | Genera una nueva migración con timestamp (ej. `bundle exec rake db:create_migration[create_users]`) |
| `db:migrate` | Ejecuta migraciones pendientes y actualiza `db/schema.rb` |
| `db:rollback[steps]` | Revierte la(s) última(s) migración(es) y actualiza `db/schema.rb`. Ej: `bundle exec rake db:rollback[3]` (default: 1) |
| `db:seed` | Ejecuta `db/seeds.rb` |
| `db:setup` | Ejecuta create + migrate + seed en secuencia |
| `console` | Abre una sesión interactiva **Pry** con el entorno completo cargado |
| `rabbitmq:publish_sample` | Publica un mensaje de prueba en la cola `battle_events` de RabbitMQ |

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

## Variables de entorno

| Variable | Default | Descripción |
|---|---|---|
| `APP_ENV` | `development` | Entorno de la app |
| `DATABASE_URL` | `postgres://postgres:admin@localhost:5432/battle_engine_development` | URL de conexión PostgreSQL |
| `RABBITMQ_URL` | `amqp://guest:admin@localhost:5672` | URL de conexión RabbitMQ |
| `LOG_LEVEL` | `debug` | Nivel de log (`debug`, `info`, `warn`, `error`, `fatal`) |

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
│   └── consumers/
│       └── battle_events_consumer.rb  # Consumer RabbitMQ
│
├── db/
│   ├── schema.rb        # Esquema ActiveRecord
│   ├── migrate/         # Migraciones
│   └── seeds.rb         # Datos iniciales
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


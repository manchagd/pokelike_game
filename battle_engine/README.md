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
ruby scripts/db_setup
```

## Setup con Docker (desde la raíz del proyecto)

```bash
# Levanta PostgreSQL y RabbitMQ
docker compose up -d postgres rabbitmq

# Crea la base de datos
docker compose run battle_engine ruby scripts/db_create

# Corre migraciones
docker compose run battle_engine ruby scripts/db_migrate

# Seeds
docker compose run battle_engine ruby scripts/db_seed

# O todo junto:
docker compose run battle_engine ruby scripts/db_setup
```

## Scripts disponibles

Todos los scripts están en `scripts/` y se ejecutan con `ruby scripts/<nombre>`:

| Script | Descripción |
|---|---|
| `db_create` | Crea la base de datos (`battle_engine_<APP_ENV>`) |
| `db_drop` | Elimina la base de datos |
| `db_migrate` | Ejecuta migraciones pendientes |
| `db_rollback` | Revierte la última migración. Acepta argumento: `ruby scripts/db_rollback 3` |
| `db_seed` | Ejecuta `db/seeds.rb` |
| `db_setup` | Ejecuta create + migrate + seed en secuencia |
| `console` | Abre una sesión **Pry** con el entorno completo cargado |
| `publish_sample_message` | Publica un mensaje de prueba en la cola `battle_events` de RabbitMQ |

## Arquitectura de Boot

El flujo de carga es:

```
boot.rb
  ├── dotenv/load          (carga .env si existe)
  └── config/environment.rb
        ├── app_config.rb   (lee ENV vars)
        ├── logger.rb       (stdout + archivo log)
        ├── database.rb     (ActiveRecord → PostgreSQL)
        ├── rabbitmq.rb     (Bunny → RabbitMQ)
        └── Zeitwerk        (autoload de app/)
```

1. **`boot.rb`** — Entry point. Carga dotenv (solo si existe `.env`), requiere `config/environment.rb`, y conecta a la DB.
2. **`config/app_config.rb`** — Módulo que lee variables de entorno con valores por defecto.
3. **`config/logger.rb`** — Logger dual: escribe a `STDOUT` y a `log/<APP_ENV>.log`.
4. **`config/database.rb`** — Establece la conexión ActiveRecord con PostgreSQL.
5. **`config/rabbitmq.rb`** — Maneja la conexión Bunny (connect/disconnect/channel).
6. **`config/environment.rb`** — Orquesta la carga: requiere los módulos anteriores y configura Zeitwerk para autoload de `app/`.

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
├── Dockerfile           # Imagen Docker
├── .env.example         # Variables de entorno (ejemplo)
├── boot.rb              # Entry point
├── README.md            # Este archivo
│
├── config/
│   ├── environment.rb   # Orquestador de carga
│   ├── app_config.rb    # Lectura de ENV
│   ├── database.rb      # Conexión PostgreSQL
│   ├── rabbitmq.rb      # Conexión RabbitMQ
│   └── logger.rb        # Logger dual
│
├── db/
│   ├── schema.rb        # Esquema ActiveRecord
│   ├── migrate/         # Migraciones
│   └── seeds.rb         # Datos iniciales
│
├── app/                 # Modelos, servicios (autoloaded por Zeitwerk)
│
├── scripts/             # Utilidades CLI
│   ├── db_create
│   ├── db_drop
│   ├── db_migrate
│   ├── db_rollback
│   ├── db_seed
│   ├── db_setup
│   ├── console
│   └── publish_sample_message
│
└── log/                 # Archivos de log (ignorados por git)
```

## Verificación

```bash
# Verificar conexión a la DB
ruby scripts/db_create
ruby scripts/db_migrate

# Verificar conexión a RabbitMQ
ruby scripts/publish_sample_message

# Consola interactiva
ruby scripts/console

# RabbitMQ Management UI
open http://localhost:15672   # user: guest / pass: admin
```

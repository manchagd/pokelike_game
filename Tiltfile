# -*- mode: Python -*-
# Tiltfile para pokelike_game
# Orquestación de desarrollo local con Docker Compose

# 1. Cargar servicios desde docker-compose.yml
docker_compose('docker-compose.yml')

# 2. Infraestructura Base
dc_resource(
    'postgres',
    labels=['infra']
)

dc_resource(
    'rabbitmq',
    labels=['infra'],
    links=['http://localhost:15672']
)

# 3. Servidor de Tiempo Real (Elixir / Phoenix)
dc_resource(
    'battle_real_time',
    labels=['backend'],
    links=['http://localhost:4000']
)

# 4. Motor de Batalla (Ruby)
dc_resource(
    'battle_engine',
    labels=['backend']
)

# 5. Rutinas de Base de Datos (Tareas bajo demanda en Tilt Dashboard)
local_resource(
    name='db:create',
    cmd='docker compose exec -T battle_engine bundle exec rake db:create',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['database']
)

local_resource(
    name='db:migrate',
    cmd='docker compose exec -T battle_engine bundle exec rake db:migrate',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['database']
)

local_resource(
    name='db:seed',
    cmd='docker compose exec -T battle_engine bundle exec rake db:seed',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['database']
)

local_resource(
    name='db:setup',
    cmd='docker compose exec -T battle_engine bundle exec rake db:setup',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['database']
)

local_resource(
    name='db:purge',
    cmd='docker compose exec -T battle_engine bundle exec rake db:purge_battles',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['database']
)

local_resource(
    name='db:drop',
    cmd='docker compose exec -T battle_engine bundle exec rake db:drop',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['database']
)

# 6. Recarga Rápida y Ciclo de Vida (Quick Recharge vs Rebuild)
local_resource(
    name='engine:restart',
    cmd='docker compose restart battle_engine',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['devops']
)

local_resource(
    name='engine:rebuild',
    cmd='docker compose build battle_engine && docker compose up -d --no-deps battle_engine',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['devops']
)

local_resource(
    name='realtime:restart',
    cmd='docker compose restart battle_real_time',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_real_time'],
    labels=['devops']
)

# 7. Tareas de Testing
local_resource(
    name='test:ruby',
    cmd='docker compose exec -T battle_engine bundle exec rspec',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_engine'],
    labels=['tests']
)

local_resource(
    name='test:elixir',
    cmd='docker compose exec -T -e MIX_ENV=test battle_real_time mix test',
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    resource_deps=['battle_real_time'],
    labels=['tests']
)

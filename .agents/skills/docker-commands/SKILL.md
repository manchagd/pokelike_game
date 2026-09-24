---
name: docker-commands
description: >-
  Instrucciones y reglas para la ejecución de comandos de Ruby y Elixir
  dentro de contenedores Docker utilizando Docker Compose en este workspace.
---

# Ejecución de Comandos con Docker
Todos los comandos de Ruby y Elixir deben ejecutarse dentro de los contenedores Docker utilizando `docker compose run --rm` o `docker compose exec`.

## 1. Entorno Ruby (battle_engine)
Aplicacion ruby sin rails, posee rake task para base de datos, seeds y tareas de publicacion en rabbitmq

## 2. Entorno Elixir (battle_real_time)
Aplicacion de Elixir en phoenix con tools para ejecutar tareas mix

## 3. Comandos Generales de Infraestructura (Docker Compose)
Ejecuta estos comandos en la raíz del proyecto para controlar los servicios e infraestructura compartida (PostgreSQL, RabbitMQ):

## 4. Orquestación con Tilt (Recomendado para Desarrollo Local)
El proyecto cuenta con un `Tiltfile` para desarrollo local interactivo:
- Iniciar el entorno: `mise exec -- tilt up` o simplemente `tilt up`
- Detener el entorno: `tilt down`
- Dashboard Web: `http://localhost:10350`
- Tareas bajo demanda en Tilt UI:
  - Base de datos (`db:create`, `db:migrate`, `db:seed`, `db:setup`, `db:purge`, `db:drop`)
  - Recarga y DevOps (`engine:restart`, `engine:rebuild`, `realtime:restart`)
  - Tests (`test:ruby`, `test:elixir`)


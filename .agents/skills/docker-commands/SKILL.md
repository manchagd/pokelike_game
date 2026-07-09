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

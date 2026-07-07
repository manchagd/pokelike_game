---
name: ruby-messaging-contracts
description: >-
  Reglas para el diseño, validación y verificación de contratos de mensajería (Dry-Validation),
  consumers, publishers y servicios en el motor de batalla Ruby (battle_engine).
---

# Contratos y Mensajería en Ruby (battle_engine)

Define las reglas de diseño para la mensajería asíncrona sobre RabbitMQ en la aplicación de Ruby (`battle_engine`).

## 1. Arquitectura de Mensajería en Ruby
El motor de batalla procesa mensajes de entrada (consumers) y genera mensajes de salida (publishers). Ambos flujos están regidos por contratos estrictos utilizando la gema `dry-validation`.

La estructura de carpetas en `app/` es la siguiente:
*   `app/consumers/`: Contiene los consumidores de las colas de RabbitMQ (heredan de `Consumers::BaseConsumer`).
*   `app/contracts/`: Contiene los contratos de validación de esquemas y tipos.
    *   `app/contracts/consumers/`: Contratos para mensajes recibidos.
    *   `app/contracts/publishers/`: Contratos para mensajes enviados.
*   `app/services/consumers/`: Servicios de negocio invocados directamente por los consumidores al procesar un evento.
*   `app/publishers/`: Clases responsables de serializar y enviar mensajes a las colas de RabbitMQ (heredan de `Publishers::BasePublisher`).
*   `app/messages/*_events/`: Contiene los payloads de los mensajes que se envian a las colas de RabbitMQ, dentro de cada carpeta existe dos archivos: `events.rb` y `payloads.rb`, definiendo la cosntante de los eventos y serializacion de cada payload. 

## 2. Reglas para Nuevas Acciones / Mensajes

Cuando implementes un nuevo evento, sigue obligatoriamente estos pasos:

### Paso A: Definir el Contrato del Mensaje
*   Si el evento es **recibido** por un consumer, crea un contrato en `app/contracts/consumers/nombre_del_evento_contract.rb`:
    ```ruby
    # frozen_string_literal: true

    module Contracts
      module Consumers
        class NombreDelEventoContract < Dry::Validation::Contract
          params do
            required(:battle_id).filled(:string)
            required(:player_id).filled(:integer)
            optional(:timestamp).maybe(:string)
          end
        end
      end
    end
    ```
*   Si el evento es **enviado** por un publisher, crea un contrato similar bajo el módulo `Contracts::Publishers::NombreDelEventoContract` en `app/contracts/publishers/nombre_del_evento_contract.rb`.

### Paso B: Definir el Servicio de Negocio
*   Los consumers delegarán directamente en un servicio bajo `app/services/consumers/nombre_del_evento_event.rb` que implementa un método `call(payload)`:
    ```ruby
    # frozen_string_literal: true

    module Services
      module Consumers
        class NombreDelEventoEvent
          def call(payload)
            # 1. Extraer los datos ya validados por el contrato
            battle_id = payload[:battle_id]
            player_id = payload[:player_id]

            # 2. Lógica de negocio (ej. llamar a un modelo o interactuar con la base de datos)
            battle = Battle.find_by!(uuid: battle_id)
            # ...
          end
        end
      end
    end
    ```

### Paso C: Revisar los Modelos y Estructuras de Datos
*   Asegúrate de que los campos declarados en los contratos coincidan en tipo y semántica con los atributos del modelo ActiveRecord (ej. base de datos PostgreSQL) y los payloads JSON intercambiados.
*   Siempre verifica los eventos generados por los servicios para asegurar que los payloads pasen la validación del contrato del publisher correspondiente.

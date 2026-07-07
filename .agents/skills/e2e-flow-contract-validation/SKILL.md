---
name: e2e-flow-contract-validation
description: >-
  Metodología para el análisis de flujos de extremo a extremo (E2E) entre Elixir y Ruby,
  garantizando la consistencia de contratos y validando los 3 caminos de ejecución.
---

# Validación de Contratos y Flujos E2E

Cuando se diseña o implementa una nueva funcionalidad que involucra el flujo completo de la aplicación: desde el cliente hasta el motor de simulación y de regreso, realiza las siguientes verificaciones para evitar incompatibilidades de integración:

## 1. Consistencia de Contratos
### 1.1 Publishers
- **Elixir** 
    - Los eventos de Elixir van en colas con el nombre `*_actions`.
    - Estos eventos deben ser publicados por un publisher correspondiente a cada comando que se ejecute, el cual implementa un validate function, que validar los campos y tipos que se van a enviar.
    - Debe poseer un contrato para cada action que desee publicar desde el publisher correspondiente, que es llamado por cada comando que se ejecute. El contrato debe estar en el directorio `contracts/publishers/` y debe seguir el formato de Ecto.Changeset.
- **Ruby**
    - Los eventos de Ruby van en colas con el nombre `*_events`.
    - Estos eventos deben ser publicados por un publisher correspondiente a cada comando que se ejecute.
    - Debe poseer un contrato para cada action que desee publicar desde el publisher correspondiente, que es llamado por cada comando que se ejecute. El contrato debe estar en el directorio `contracts/publishers/<action>_contract.rb` y debe ser un Dry::Validation::Contract.
### 1.2 Consumers
- **Elixir**
    - Los consumidores de Elixir van en colas con el nombre `*_events`.
    - Los consumidores de Elixir deben poseer un contrato para cada action que deseen recibir desde el publisher correspondiente, que es llamado por cada comando que se ejecute. 
    - Estos contratos deben estar en el directorio `contracts/consumers/` y debe seguir el formato de Ecto.Changeset.
- **Ruby**
    - Los consumidores de Ruby van en colas con el nombre `*_actions`.
    - Los consumidores de Ruby deben poseer un contrato para cada action que deseen recibir desde el publisher correspondiente, que es llamado por cada comando que se ejecute.
    - Estos contratos deben estar en el directorio `contracts/consumers/<action>_contract.rb` y debe ser un Dry::Validation::Contract.


## 2. Validación de Flujos E2E
Cuando se diseña o implementa una nueva funcionalidad que involucra el flujo completo de la aplicación: desde el cliente hasta el motor de simulación y de regreso, realiza las siguientes verificaciones para evitar incompatibilidades de integración:

### 2.1 Validación de Canales
- **RabbitMQ**: Verifica que los nombres de las colas (`*_events` para mensajes desde Ruby a Elixir, `*_actions` para mensajes desde Elixir a Ruby) sean consistentes en ambos sistemas.
- **Phoenix Channels**: Asegura que la suscripción y publicación de eventos en tiempo real se realicen a través de canales con nombres correctos.

### 2.2 Validación de Contratos
- **Publishers**: 
    - **Elixir**: Los eventos de Elixir van en colas con el nombre `*_actions`. Deben ser publicados por un publisher que implemente `validate` para validar campos y tipos antes de enviar.
    - **Ruby**: Los eventos de Ruby van en colas con el nombre `*_events`. Deben ser publicados por un publisher que posea un contrato (Dry::Validation::Contract) para cada acción.
- **Consumers**:
    - **Elixir**: Los consumidores de Elixir van en colas con el nombre `*_events`. Deben poseer contratos (Ecto.Changeset) para cada acción que deseen recibir.
    - **Ruby**: Los consumidores de Ruby van en colas con el nombre `*_actions`. Deben poseer contratos (Dry::Validation::Contract) para cada acción que deseen recibir.

## 3. Validación de los 3 Caminos de Flujo

Toda lógica de flujo completo debe analizar y verificar el comportamiento en tres caminos de ejecución diferentes:

### Camino 1: Happy Path (Camino Exitoso)
*   **Condiciones:** Todos los datos enviados son válidos y la base de datos se encuentra en un estado que permite la acción.
*   **Verificación:** 
    *   Los datos se guardan/actualizan correctamente en PostgreSQL.
    *   Se emite el evento de éxito correspondiente por RabbitMQ.
    *   El cliente recibe la notificación de éxito en tiempo real.

### Camino 2: Validación / Error de Negocio (Business Error Path)
*   **Condiciones:** El usuario envía parámetros incorrectos (ej. campo faltante, tipo incorrecto) o realiza una acción no permitida por las reglas del juego (ej. unirse a una batalla llena, usar un pokémon no permitido).
*   **Verificación:**
    *   Los contratos detectan y rechazan el mensaje inválido a nivel de esquema.
    *   Si pasa el contrato pero viola una regla de negocio en el servicio, la transacción de base de datos no se aplica y se reporta un error estructurado.
    *   El sistema loguea los errores correspondientes, sin crashear.

### Camino 3: Falla del Sistema / Recuperación (System Failure Path)
*   **Condiciones:** Ocurren problemas de infraestructura o fallas técnicas inesperadas durante el procesamiento (ej. pérdida de conexión con RabbitMQ, caída temporal de la base de datos PostgreSQL, errores inesperados de código).
*   **Verificación:**
    *   **Transaccionalidad en Ruby:** El servicio de Ruby debe envolver las operaciones críticas de base de datos en bloques `ActiveRecord::Base.transaction` para asegurar que ningún cambio parcial sea persistido en caso de error.
    *   **Robustez de Canales:** Si el motor de Ruby falla y no responde, el canal de Phoenix o el cliente no deben quedarse colgados indefinidamente (implementar timeouts o estados de error en el cliente si es necesario).
    *   **Reconexión:** Los publishers de RabbitMQ en Elixir y Ruby deben estar preparados para encolar o reintentar publicaciones cuando se caiga la conexión.

---
name: elixir-channels-business-logic
description: >-
  Reglas para separar los Canales de Phoenix (capa de transporte) de la lógica de negocio core,
  y pautas para el diseño y validación de contratos basados en Ecto en Elixir (battle_real_time).
---

# Lógica de Canales y Contratos en Elixir (battle_real_time)

Describe arquitectura para mantener una separación de responsabilidades limpia entre la capa de WebSockets y la lógica de negocio en la aplicación.

## 1. Separación Estricta: Canales vs. Negocio

Los Canales de Phoenix (`lib/battle_real_time_web/channels/`) deben ser lo más delgados posible.

### Responsabilidades del Canal (WebSockets)
*   Manejar el ciclo de vida del socket (`join/3`, `terminate/2`).
*   Recibir mensajes del cliente (`handle_in/3`).
*   Administrar los *assigns* del socket (ej: `socket.assigns.player_id`).
*   **Delegar inmediatamente** la acción a un módulo de servicio de negocio específico.
*   Retornar una respuesta simple (`{:noreply, socket}`).
*   Pushear eventos salientes al cliente (`push/3`).

### Responsabilidades de la Lógica de Negocio (Servicios/Acciones)
Toda la lógica de negocio y comunicación con RabbitMQ debe residir fuera de los canales, típicamente bajo los módulos de contexto, su modulo debe ser consistente al nombre del channel pluralizado:
*   `lib/battle_real_time/<channel_name_plural>/` (ej: `BattleRealTime.Players.CreateBattle`)

#### Ejemplo de Canal Delgado
```elixir
defmodule BattleRealTimeWeb.PlayerChannel do
  use Phoenix.Channel

  # INCORRECTO: Evita publicar a RabbitMQ o validar datos directamente aquí
  # CORRECTO: Delegar a la lógica de negocio
  def handle_in("create_battle", payload, socket) do
    player_id = socket.assigns.identifier
    team_id = Map.get(payload, "team_id")

    case BattleRealTime.Players.CreateBattle.call(player_id, team_id) do
      {:ok, _payload} -> {:noreply, socket}
      {:error, reason} -> {:noreply, socket}
    end
  end
end
```

---

## 2. Contratos de Validación basados en Ecto

Para garantizar la integridad de los mensajes distribuidos, toda entrada/salida de RabbitMQ debe ser validada mediante un contrato.

### Ubicación de los Contratos
*   `lib/battle_real_time/contracts/consumers/`: Contratos para mensajes consumidos de RabbitMQ (eventos del motor de Ruby).
*   `lib/battle_real_time/contracts/publishers/`: Contratos para mensajes publicados a RabbitMQ (acciones enviadas al motor de Ruby).

### Estructura de un Contrato Ecto
Los contratos utilizan `use BattleRealTime.Contracts.Contract` y definen un `embedded_schema`:
```elixir
defmodule BattleRealTime.Contracts.Publishers.PlayerActions.CreateBattleContract do
  use BattleRealTime.Contracts.Contract

  @primary_key false
  embedded_schema do
    field(:player_id, :integer)
    field(:team_id, :integer)
    field(:timestamp, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:player_id, :team_id, :timestamp])
    |> validate_required([:player_id, :team_id])
  end
end
```

---

## 3. Integración en Publishers

Cada módulo publicador (`lib/battle_real_time/amqp/publishers/...`) debe registrar explícitamente sus validaciones implementando el callback `validate/2` de la siguiente forma:

```elixir
defmodule BattleRealTime.AMQP.Publishers.PlayerActionsPublisher do
  use BattleRealTime.AMQP.Publisher, queue: "player_actions"

  alias BattleRealTime.Contracts.Publishers.PlayerActions.CreateBattleContract

  @impl true
  def validate("create_battle", payload), do: CreateBattleContract.validate(payload)
  def validate(action, payload), do: super(action, payload)
end
```

# frozen_string_literal: true

require "faraday"
require "json"

# ==========================================
# 2. POPULATE MOVES (Original static seeding)
# ==========================================

moves_list = [
  {
    name: "Tackle",
    type: "Normal",
    secondary_type: nil,
    category: "Physical",
    pp: 35,
    power: 40,
    priority: 0,
    accuracy: 100
  },
  {
    name: "Flamethrower",
    type: "Fire",
    secondary_type: nil,
    category: "Special",
    pp: 15,
    power: 90,
    priority: 0,
    accuracy: 100
  },
  {
    name: "Thunder Wave",
    type: "Electric",
    secondary_type: nil,
    category: "Status",
    pp: 20,
    power: nil, # Los movimientos de estado no suelen tener poder base
    priority: 0,
    accuracy: 90
  },
  {
    name: "Quick Attack",
    type: "Normal",
    secondary_type: nil,
    category: "Physical",
    pp: 30,
    power: 40,
    priority: 1, # Este ataque tiene prioridad alta
    accuracy: 100
  },
  {
    name: "Flying Press",
    type: "Fighting",
    secondary_type: "Flying", # Este es el único movimiento que maneja dos tipos simultáneos
    category: "Physical",
    pp: 10,
    power: 100,
    priority: 0,
    accuracy: 95
  }
]

# Método para poblar la base de datos evitando duplicados
moves_list.each do |move_data|
  Move.find_or_create_by!(name: move_data[:name]) do |m|
    m.type           = move_data[:type]
    m.secondary_type = move_data[:secondary_type]
    m.category       = move_data[:category]
    m.pp             = move_data[:pp]
    m.power          = move_data[:power]
    m.priority       = move_data[:priority]
    m.accuracy       = move_data[:accuracy]
  end
end

puts "¡Se han registrado #{Move.count} movimientos correctamente!"

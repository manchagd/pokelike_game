# frozen_string_literal: true

# Seed data for battle_engine
# Add your seed data here. Example:
#
#   Pokemon.create!(name: "Pikachu", type: "Electric", hp: 35)
#

BattleEngine.logger.info("[Seeds] No seeds to run yet")

pokemon_list = [
  { name: "Bulbasaur", types: ["Grass", "Poison"], stats: { hp: 45, atk: 49, def: 49, sp_atk: 65, sp_def: 65, spd: 45 } },
  { name: "Ivysaur", types: ["Grass", "Poison"], stats: { hp: 60, atk: 62, def: 63, sp_atk: 80, sp_def: 80, spd: 60 } },
  { name: "Venusaur", types: ["Grass", "Poison"], stats: { hp: 80, atk: 82, def: 83, sp_atk: 100, sp_def: 100, spd: 80 } },
  { name: "Charmander", types: ["Fire"], stats: { hp: 39, atk: 52, def: 43, sp_atk: 60, sp_def: 50, spd: 65 } },
  { name: "Charmeleon", types: ["Fire"], stats: { hp: 58, atk: 64, def: 58, sp_atk: 80, sp_def: 65, spd: 80 } },
  { name: "Charizard", types: ["Fire", "Flying"], stats: { hp: 78, atk: 84, def: 78, sp_atk: 109, sp_def: 85, spd: 100 } },
  { name: "Squirtle", types: ["Water"], stats: { hp: 44, atk: 48, def: 65, sp_atk: 50, sp_def: 64, spd: 43 } },
  { name: "Wartortle", types: ["Water"], stats: { hp: 59, atk: 63, def: 80, sp_atk: 65, sp_def: 80, spd: 58 } },
  { name: "Blastoise", types: ["Water"], stats: { hp: 79, atk: 83, def: 100, sp_atk: 85, sp_def: 105, spd: 78 } },
  { name: "Caterpie", types: ["Bug"], stats: { hp: 45, atk: 30, def: 35, sp_atk: 20, sp_def: 20, spd: 45 } },
  { name: "Metapod", types: ["Bug"], stats: { hp: 50, atk: 20, def: 55, sp_atk: 25, sp_def: 25, spd: 30 } },
  { name: "Butterfree", types: ["Bug", "Flying"], stats: { hp: 60, atk: 45, def: 50, sp_atk: 90, sp_def: 80, spd: 70 } },
  { name: "Weedle", types: ["Bug", "Poison"], stats: { hp: 40, atk: 35, def: 30, sp_atk: 20, sp_def: 20, spd: 50 } },
  { name: "Kakuna", types: ["Bug", "Poison"], stats: { hp: 45, atk: 25, def: 50, sp_atk: 25, sp_def: 25, spd: 35 } },
  { name: "Beedrill", types: ["Bug", "Poison"], stats: { hp: 65, atk: 90, def: 40, sp_atk: 45, sp_def: 80, spd: 75 } },
  { name: "Pidgey", types: ["Normal", "Flying"], stats: { hp: 40, atk: 45, def: 40, sp_atk: 35, sp_def: 35, spd: 56 } },
  { name: "Pidgeotto", types: ["Normal", "Flying"], stats: { hp: 63, atk: 60, def: 55, sp_atk: 50, sp_def: 50, spd: 71 } },
  { name: "Pidgeot", types: ["Normal", "Flying"], stats: { hp: 83, atk: 80, def: 75, sp_atk: 70, sp_def: 70, spd: 101 } },
  { name: "Rattata", types: ["Normal"], stats: { hp: 30, atk: 56, def: 35, sp_atk: 25, sp_def: 35, spd: 72 } },
  { name: "Raticate", types: ["Normal"], stats: { hp: 55, atk: 81, def: 60, sp_atk: 50, sp_def: 70, spd: 97 } },
  { name: "Spearow", types: ["Normal", "Flying"], stats: { hp: 40, atk: 60, def: 30, sp_atk: 31, sp_def: 31, spd: 70 } },
  { name: "Fearow", types: ["Normal", "Flying"], stats: { hp: 65, atk: 90, def: 65, sp_atk: 61, sp_def: 61, spd: 100 } },
  { name: "Ekans", types: ["Poison"], stats: { hp: 35, atk: 60, def: 44, sp_atk: 40, sp_def: 54, spd: 55 } },
  { name: "Arbok", types: ["Poison"], stats: { hp: 60, atk: 95, def: 69, sp_atk: 65, sp_def: 79, spd: 80 } },
  { name: "Pikachu", types: ["Electric"], stats: { hp: 35, atk: 55, def: 40, sp_atk: 50, sp_def: 50, spd: 90 } },
  { name: "Raichu", types: ["Electric"], stats: { hp: 60, atk: 90, def: 55, sp_atk: 90, sp_def: 80, spd: 110 } },
  { name: "Sandshrew", types: ["Ground"], stats: { hp: 50, atk: 75, def: 85, sp_atk: 20, sp_def: 30, spd: 40 } },
  { name: "Sandslash", types: ["Ground"], stats: { hp: 75, atk: 100, def: 110, sp_atk: 45, sp_def: 55, spd: 65 } },
  { name: "Nidoran♀", types: ["Poison"], stats: { hp: 55, atk: 47, def: 52, sp_atk: 40, sp_def: 40, spd: 41 } },
  { name: "Nidorina", types: ["Poison"], stats: { hp: 70, atk: 62, def: 67, sp_atk: 55, sp_def: 55, spd: 56 } },
  { name: "Nidoqueen", types: ["Poison", "Ground"], stats: { hp: 90, atk: 92, def: 87, sp_atk: 75, sp_def: 85, spd: 76 } },
  { name: "Nidoran♂", types: ["Poison"], stats: { hp: 46, atk: 57, def: 40, sp_atk: 40, sp_def: 40, spd: 50 } },
  { name: "Nidorino", types: ["Poison"], stats: { hp: 61, atk: 72, def: 57, sp_atk: 55, sp_def: 55, spd: 65 } },
  { name: "Nidoking", types: ["Poison", "Ground"], stats: { hp: 81, atk: 102, def: 77, sp_atk: 85, sp_def: 75, spd: 85 } },
  { name: "Clefairy", types: ["Fairy"], stats: { hp: 70, atk: 45, def: 48, sp_atk: 60, sp_def: 65, spd: 35 } },
  { name: "Clefable", types: ["Fairy"], stats: { hp: 95, atk: 70, def: 73, sp_atk: 95, sp_def: 90, spd: 60 } },
  { name: "Vulpix", types: ["Fire"], stats: { hp: 38, atk: 41, def: 40, sp_atk: 50, sp_def: 65, spd: 65 } },
  { name: "Ninetales", types: ["Fire"], stats: { hp: 73, atk: 76, def: 75, sp_atk: 81, sp_def: 100, spd: 100 } },
  { name: "Jigglypuff", types: ["Normal", "Fairy"], stats: { hp: 115, atk: 45, def: 20, sp_atk: 45, sp_def: 25, spd: 20 } },
  { name: "Wigglytuff", types: ["Normal", "Fairy"], stats: { hp: 140, atk: 70, def: 45, sp_atk: 85, sp_def: 50, spd: 45 } },
  { name: "Zubat", types: ["Poison", "Flying"], stats: { hp: 40, atk: 45, def: 35, sp_atk: 30, sp_def: 40, spd: 55 } },
  { name: "Golbat", types: ["Poison", "Flying"], stats: { hp: 75, atk: 80, def: 70, sp_atk: 65, sp_def: 75, spd: 90 } },
  { name: "Oddish", types: ["Grass", "Poison"], stats: { hp: 45, atk: 50, def: 55, sp_atk: 75, sp_def: 65, spd: 30 } },
  { name: "Gloom", types: ["Grass", "Poison"], stats: { hp: 60, atk: 65, def: 70, sp_atk: 85, sp_def: 75, spd: 40 } },
  { name: "Vileplume", types: ["Grass", "Poison"], stats: { hp: 75, atk: 80, def: 85, sp_atk: 110, sp_def: 90, spd: 50 } },
  { name: "Paras", types: ["Bug", "Grass"], stats: { hp: 35, atk: 70, def: 55, sp_atk: 45, sp_def: 55, spd: 25 } },
  { name: "Parasect", types: ["Bug", "Grass"], stats: { hp: 60, atk: 95, def: 80, sp_atk: 60, sp_def: 80, spd: 30 } },
  { name: "Venonat", types: ["Bug", "Poison"], stats: { hp: 60, atk: 55, def: 50, sp_atk: 40, sp_def: 55, spd: 45 } },
  { name: "Venomoth", types: ["Bug", "Poison"], stats: { hp: 70, atk: 65, def: 60, sp_atk: 90, sp_def: 75, spd: 90 } },
  { name: "Diglett", types: ["Ground"], stats: { hp: 10, atk: 55, def: 25, sp_atk: 35, sp_def: 45, spd: 95 } },
  { name: "Dugtrio", types: ["Ground"], stats: { hp: 35, atk: 100, def: 50, sp_atk: 50, sp_def: 70, spd: 120 } },
  { name: "Meowth", types: ["Normal"], stats: { hp: 40, atk: 45, def: 35, sp_atk: 40, sp_def: 40, spd: 90 } },
  { name: "Persian", types: ["Normal"], stats: { hp: 65, atk: 70, def: 60, sp_atk: 65, sp_def: 65, spd: 115 } },
  { name: "Psydwuck", types: ["Water"], stats: { hp: 50, atk: 52, def: 48, sp_atk: 65, sp_def: 50, spd: 55 } },
  { name: "Golduck", types: ["Water"], stats: { hp: 80, atk: 82, def: 78, sp_atk: 95, sp_def: 80, spd: 85 } },
  { name: "Mankey", types: ["Fighting"], stats: { hp: 40, atk: 80, def: 35, sp_atk: 35, sp_def: 45, spd: 70 } },
  { name: "Primeape", types: ["Fighting"], stats: { hp: 65, atk: 105, def: 60, sp_atk: 60, sp_def: 70, spd: 95 } },
  { name: "Growlithe", types: ["Fire"], stats: { hp: 55, atk: 70, def: 45, sp_atk: 70, sp_def: 50, spd: 60 } },
  { name: "Arcanine", types: ["Fire"], stats: { hp: 90, atk: 110, def: 80, sp_atk: 100, sp_def: 80, spd: 95 } },
  { name: "Poliwag", types: ["Water"], stats: { hp: 40, atk: 50, def: 40, sp_atk: 40, sp_def: 40, spd: 90 } },
  { name: "Poliwhirl", types: ["Water"], stats: { hp: 65, atk: 65, def: 65, sp_atk: 50, sp_def: 50, spd: 90 } },
  { name: "Poliwrath", types: ["Water", "Fighting"], stats: { hp: 90, atk: 95, def: 95, sp_atk: 70, sp_def: 90, spd: 70 } },
  { name: "Abra", types: ["Psychic"], stats: { hp: 25, atk: 20, def: 15, sp_atk: 105, sp_def: 55, spd: 90 } },
  { name: "Kadabra", types: ["Psychic"], stats: { hp: 40, atk: 35, def: 30, sp_atk: 120, sp_def: 70, spd: 105 } },
  { name: "Alakazam", types: ["Psychic"], stats: { hp: 55, atk: 50, def: 45, sp_atk: 135, sp_def: 95, spd: 120 } },
  { name: "Machop", types: ["Fighting"], stats: { hp: 70, atk: 80, def: 50, sp_atk: 35, sp_def: 35, spd: 35 } },
  { name: "Machoke", types: ["Fighting"], stats: { hp: 80, atk: 100, def: 70, sp_atk: 50, sp_def: 60, spd: 45 } },
  { name: "Machamp", types: ["Fighting"], stats: { hp: 90, atk: 130, def: 80, sp_atk: 65, sp_def: 85, spd: 55 } },
  { name: "Bellsprout", types: ["Grass", "Poison"], stats: { hp: 50, atk: 75, def: 35, sp_atk: 70, sp_def: 30, spd: 40 } },
  { name: "Weepinbell", types: ["Grass", "Poison"], stats: { hp: 65, atk: 90, def: 50, sp_atk: 85, sp_def: 45, spd: 55 } },
  { name: "Victreebel", types: ["Grass", "Poison"], stats: { hp: 80, atk: 105, def: 65, sp_atk: 100, sp_def: 70, spd: 70 } },
  { name: "Tentacool", types: ["Water", "Poison"], stats: { hp: 40, atk: 40, def: 35, sp_atk: 50, sp_def: 100, spd: 70 } },
  { name: "Tentacruel", types: ["Water", "Poison"], stats: { hp: 80, atk: 70, def: 65, sp_atk: 80, sp_def: 120, spd: 100 } },
  { name: "Geodude", types: ["Rock", "Ground"], stats: { hp: 40, atk: 80, def: 100, sp_atk: 30, sp_def: 30, spd: 20 } },
  { name: "Graveler", types: ["Rock", "Ground"], stats: { hp: 55, atk: 95, def: 115, sp_atk: 45, sp_def: 45, spd: 35 } },
  { name: "Golem", types: ["Rock", "Ground"], stats: { hp: 80, atk: 120, def: 130, sp_atk: 55, sp_def: 65, spd: 45 } },
  { name: "Ponyta", types: ["Fire"], stats: { hp: 50, atk: 85, def: 55, sp_atk: 65, sp_def: 65, spd: 90 } },
  { name: "Rapidash", types: ["Fire"], stats: { hp: 65, atk: 100, def: 70, sp_atk: 80, sp_def: 80, spd: 105 } },
  { name: "Slowpoke", types: ["Water", "Psychic"], stats: { hp: 90, atk: 65, def: 65, sp_atk: 40, sp_def: 40, spd: 15 } },
  { name: "Slowbro", types: ["Water", "Psychic"], stats: { hp: 95, atk: 75, def: 110, sp_atk: 100, sp_def: 80, spd: 30 } },
  { name: "Magnemite", types: ["Electric", "Steel"], stats: { hp: 25, atk: 35, def: 70, sp_atk: 95, sp_def: 55, spd: 45 } },
  { name: "Magneton", types: ["Electric", "Steel"], stats: { hp: 50, atk: 60, def: 95, sp_atk: 120, sp_def: 70, spd: 70 } },
  { name: "Farfetch'd", types: ["Normal", "Flying"], stats: { hp: 52, atk: 90, def: 55, sp_atk: 58, sp_def: 62, spd: 60 } },
  { name: "Doduo", types: ["Normal", "Flying"], stats: { hp: 35, atk: 85, def: 45, sp_atk: 35, sp_def: 35, spd: 75 } },
  { name: "Dodrio", types: ["Normal", "Flying"], stats: { hp: 60, atk: 110, def: 70, sp_atk: 60, sp_def: 60, spd: 110 } },
  { name: "Seel", types: ["Water"], stats: { hp: 65, atk: 45, def: 55, sp_atk: 45, sp_def: 70, spd: 45 } },
  { name: "Dewgong", types: ["Water", "Ice"], stats: { hp: 90, atk: 70, def: 80, sp_atk: 70, sp_def: 95, spd: 70 } },
  { name: "Grimer", types: ["Poison"], stats: { hp: 80, atk: 80, def: 50, sp_atk: 40, sp_def: 50, spd: 25 } },
  { name: "Muk", types: ["Poison"], stats: { hp: 105, atk: 105, def: 75, sp_atk: 65, sp_def: 100, spd: 50 } },
  { name: "Shellder", types: ["Water"], stats: { hp: 30, atk: 65, def: 100, sp_atk: 45, sp_def: 25, spd: 40 } },
  { name: "Cloyster", types: ["Water", "Ice"], stats: { hp: 50, atk: 95, def: 180, sp_atk: 85, sp_def: 45, spd: 70 } },
  { name: "Gastly", types: ["Ghost", "Poison"], stats: { hp: 30, atk: 35, def: 30, sp_atk: 100, sp_def: 35, spd: 80 } },
  { name: "Haunter", types: ["Ghost", "Poison"], stats: { hp: 45, atk: 50, def: 45, sp_atk: 115, sp_def: 55, spd: 95 } },
  { name: "Gengar", types: ["Ghost", "Poison"], stats: { hp: 60, atk: 65, def: 60, sp_atk: 130, sp_def: 75, spd: 110 } },
  { name: "Onix", types: ["Rock", "Ground"], stats: { hp: 35, atk: 45, def: 160, sp_atk: 30, sp_def: 45, spd: 70 } },
  { name: "Drowzee", types: ["Psychic"], stats: { hp: 60, atk: 48, def: 45, sp_atk: 43, sp_def: 90, spd: 42 } },
  { name: "Hypno", types: ["Psychic"], stats: { hp: 85, atk: 73, def: 70, sp_atk: 73, sp_def: 115, spd: 67 } },
  { name: "Krabby", types: ["Water"], stats: { hp: 30, atk: 105, def: 90, sp_atk: 25, sp_def: 25, spd: 50 } },
  { name: "Kingler", types: ["Water"], stats: { hp: 55, atk: 130, def: 115, sp_atk: 50, sp_def: 50, spd: 75 } },
  { name: "Voltorb", types: ["Electric"], stats: { hp: 40, atk: 30, def: 50, sp_atk: 55, sp_def: 55, spd: 100 } },
  { name: "Electrode", types: ["Electric"], stats: { hp: 60, atk: 50, def: 70, sp_atk: 80, sp_def: 80, spd: 150 } },
  { name: "Exeggcute", types: ["Grass", "Psychic"], stats: { hp: 60, atk: 40, def: 80, sp_atk: 60, sp_def: 45, spd: 40 } },
  { name: "Exeggutor", types: ["Grass", "Psychic"], stats: { hp: 95, atk: 95, def: 85, sp_atk: 125, sp_def: 75, spd: 55 } },
  { name: "Cubone", types: ["Ground"], stats: { hp: 50, atk: 50, def: 95, sp_atk: 40, sp_def: 50, spd: 35 } },
  { name: "Marowak", types: ["Ground"], stats: { hp: 60, atk: 80, def: 110, sp_atk: 50, sp_def: 80, spd: 45 } },
  { name: "Hitmonlee", types: ["Fighting"], stats: { hp: 50, atk: 120, def: 53, sp_atk: 35, sp_def: 110, spd: 87 } },
  { name: "Hitmonchan", types: ["Fighting"], stats: { hp: 50, atk: 105, def: 79, sp_atk: 35, sp_def: 110, spd: 76 } },
  { name: "Lickitung", types: ["Normal"], stats: { hp: 90, atk: 55, def: 75, sp_atk: 60, sp_def: 75, spd: 30 } },
  { name: "Koffing", types: ["Poison"], stats: { hp: 40, atk: 65, def: 95, sp_atk: 60, sp_def: 45, spd: 35 } },
  { name: "Weezing", types: ["Poison"], stats: { hp: 65, atk: 90, def: 120, sp_atk: 85, sp_def: 70, spd: 60 } },
  { name: "Rhyhorn", types: ["Ground", "Rock"], stats: { hp: 80, atk: 85, def: 95, sp_atk: 30, sp_def: 30, spd: 25 } },
  { name: "Rhydon", types: ["Ground", "Rock"], stats: { hp: 105, atk: 130, def: 120, sp_atk: 45, sp_def: 45, spd: 40 } },
  { name: "Chansey", types: ["Normal"], stats: { hp: 250, atk: 5, def: 5, sp_atk: 35, sp_def: 105, spd: 50 } },
  { name: "Tangela", types: ["Grass"], stats: { hp: 65, atk: 55, def: 115, sp_atk: 100, sp_def: 40, spd: 60 } },
  { name: "Kangaskhan", types: ["Normal"], stats: { hp: 105, atk: 95, def: 80, sp_atk: 40, sp_def: 80, spd: 90 } },
  { name: "Horsea", types: ["Water"], stats: { hp: 30, atk: 40, def: 70, sp_atk: 70, sp_def: 25, spd: 60 } },
  { name: "Seadra", types: ["Water"], stats: { hp: 55, atk: 65, def: 95, sp_atk: 95, sp_def: 45, spd: 85 } },
  { name: "Goldeen", types: ["Water"], stats: { hp: 45, atk: 67, def: 60, sp_atk: 35, sp_def: 50, spd: 63 } },
  { name: "Seaking", types: ["Water"], stats: { hp: 80, atk: 92, def: 65, sp_atk: 65, sp_def: 80, spd: 68 } },
  { name: "Staryu", types: ["Water"], stats: { hp: 30, atk: 45, def: 55, sp_atk: 70, sp_def: 55, spd: 85 } },
  { name: "Starmie", types: ["Water", "Psychic"], stats: { hp: 60, atk: 75, def: 85, sp_atk: 100, sp_def: 85, spd: 115 } },
  { name: "Mr. Mime", types: ["Psychic", "Fairy"], stats: { hp: 40, atk: 45, def: 65, sp_atk: 100, sp_def: 120, spd: 90 } },
  { name: "Scyther", types: ["Bug", "Flying"], stats: { hp: 70, atk: 110, def: 80, sp_atk: 55, sp_def: 80, spd: 105 } },
  { name: "Jynx", types: ["Ice", "Psychic"], stats: { hp: 65, atk: 50, def: 35, sp_atk: 115, sp_def: 95, spd: 95 } },
  { name: "Electabuzz", types: ["Electric"], stats: { hp: 65, atk: 83, def: 57, sp_atk: 95, sp_def: 85, spd: 105 } },
  { name: "Magmar", types: ["Fire"], stats: { hp: 65, atk: 95, def: 57, sp_atk: 100, sp_def: 85, spd: 93 } },
  { name: "Pinsir", types: ["Bug"], stats: { hp: 65, atk: 125, def: 100, sp_atk: 55, sp_def: 70, spd: 85 } },
  { name: "Tauros", types: ["Normal"], stats: { hp: 75, atk: 100, def: 95, sp_atk: 40, sp_def: 70, spd: 110 } },
  { name: "Magikarp", types: ["Water"], stats: { hp: 20, atk: 10, def: 55, sp_atk: 15, sp_def: 20, spd: 80 } },
  { name: "Gyarados", types: ["Water", "Flying"], stats: { hp: 95, atk: 125, def: 79, sp_atk: 60, sp_def: 100, spd: 81 } },
  { name: "Lapras", types: ["Water", "Ice"], stats: { hp: 130, atk: 85, def: 80, sp_atk: 85, sp_def: 95, spd: 60 } },
  { name: "Ditto", types: ["Normal"], stats: { hp: 48, atk: 48, def: 48, sp_atk: 48, sp_def: 48, spd: 48 } },
  { name: "Eevee", types: ["Normal"], stats: { hp: 55, atk: 55, def: 50, sp_atk: 45, sp_def: 65, spd: 55 } },
  { name: "Vaporeon", types: ["Water"], stats: { hp: 130, atk: 65, def: 60, sp_atk: 110, sp_def: 95, spd: 65 } },
  { name: "Jolteon", types: ["Electric"], stats: { hp: 65, atk: 65, def: 60, sp_atk: 110, sp_def: 95, spd: 130 } },
  { name: "Flareon", types: ["Fire"], stats: { hp: 65, atk: 130, def: 60, sp_atk: 95, sp_def: 110, spd: 65 } },
  { name: "Porygon", types: ["Normal"], stats: { hp: 65, atk: 60, def: 70, sp_atk: 85, sp_def: 75, spd: 40 } },
  { name: "Omanyte", types: ["Rock", "Water"], stats: { hp: 35, atk: 40, def: 100, sp_atk: 90, sp_def: 55, spd: 35 } },
  { name: "Omastar", types: ["Rock", "Water"], stats: { hp: 70, atk: 60, def: 125, sp_atk: 115, sp_def: 70, spd: 55 } },
  { name: "Kabuto", types: ["Rock", "Water"], stats: { hp: 30, atk: 80, def: 90, sp_atk: 55, sp_def: 45, spd: 55 } },
  { name: "Kabutops", types: ["Rock", "Water"], stats: { hp: 60, atk: 115, def: 105, sp_atk: 65, sp_def: 70, spd: 80 } },
  { name: "Aerodactyl", types: ["Rock", "Flying"], stats: { hp: 80, atk: 105, def: 65, sp_atk: 60, sp_def: 75, spd: 130 } },
  { name: "Snorlax", types: ["Normal"], stats: { hp: 160, atk: 110, def: 65, sp_atk: 65, sp_def: 110, spd: 30 } },
  { name: "Articuno", types: ["Ice", "Flying"], stats: { hp: 90, atk: 85, def: 100, sp_atk: 95, sp_def: 125, spd: 85 } },
  { name: "Zapdos", types: ["Electric", "Flying"], stats: { hp: 90, atk: 90, def: 85, sp_atk: 125, sp_def: 90, spd: 100 } },
  { name: "Moltres", types: ["Fire", "Flying"], stats: { hp: 90, atk: 100, def: 90, sp_atk: 125, sp_def: 85, spd: 90 } },
  { name: "Dratini", types: ["Dragon"], stats: { hp: 41, atk: 64, def: 45, sp_atk: 50, sp_def: 50, spd: 50 } },
  { name: "Dragonair", types: ["Dragon"], stats: { hp: 61, atk: 84, def: 65, sp_atk: 70, sp_def: 70, spd: 70 } },
  { name: "Dragonite", types: ["Dragon", "Flying"], stats: { hp: 91, atk: 134, def: 95, sp_atk: 100, sp_def: 100, spd: 80 } },
  { name: "Mewtwo", types: ["Psychic"], stats: { hp: 106, atk: 110, def: 90, sp_atk: 154, sp_def: 90, spd: 130 } },
  { name: "Mew", types: ["Psychic"], stats: { hp: 100, atk: 100, def: 100, sp_atk: 100, sp_def: 100, spd: 100 } }
]

# Aquí recorremos el array para crear cada registro de forma eficiente:
pokemon_list.each do |pokemon_data|
  PokemonTemplate.find_or_create_by(name: pokemon_data[:name]) do |pk|
    pk.types = pokemon_data[:types]
    pk.stats = pokemon_data[:stats]
  end
end

puts "¡Se han registrado #{PokemonTemplate.count} Pokémon con éxito!"


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
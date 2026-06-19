import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../utils/battle_socket_service.dart';
import '../utils/pokemon_type_icons.dart';

class TeamBuilderView extends StatefulWidget {
  const TeamBuilderView({super.key});

  @override
  State<TeamBuilderView> createState() => _TeamBuilderViewState();
}

class _TeamBuilderViewState extends State<TeamBuilderView> {
  bool _isEditing = false;
  bool _isSaving = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Local list of 6 editing pokemon slots
  final List<_EditingPokemon?> _editingPokemons = List.generate(6, (_) => null);
  int? _selectedSlotIndex;

  String _searchQuery = '';
  String? _selectedTypeFilter;
  int _previousTeamsCount = 0;
  int? _selectedTeamId;
  StreamSubscription? _playerEventsSub;

  @override
  void initState() {
    super.initState();
    _playerEventsSub = context.read<BattleSocketService>().playerEvents.listen((event) {
      if (event['event'] == 'teams_info' && _isSaving) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerEventsSub?.cancel();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startNewTeam(int currentTeamsCount) {
    setState(() {
      _isEditing = true;
      _isSaving = false;
      _nameController.text = '';
      _selectedSlotIndex = 0;
      _editingPokemons.fillRange(0, 6, null);
      _previousTeamsCount = currentTeamsCount;
      _selectedTeamId = null;
    });
    // Request templates from backend
    context.read<BattleSocketService>().loadPokemonTemplates();
  }

  void _selectSlot(int index) {
    setState(() {
      _selectedSlotIndex = index;
    });
    final selectedPkmn = _editingPokemons[index];
    if (selectedPkmn != null) {
      context.read<BattleSocketService>().loadPokemonTemplateMoves(selectedPkmn.templateId);
    }
  }

  void _addPokemonToSelectedSlot(Map<String, dynamic> template) {
    if (_selectedSlotIndex == null) return;

    final index = _selectedSlotIndex!;
    final templateId = template['id'] as int;

    setState(() {
      _editingPokemons[index] = _EditingPokemon(
        templateId: templateId,
        name: template['name'] ?? 'Pokémon',
        nickname: template['name'] ?? 'Pokémon',
        types: List<String>.from(template['types'] ?? []),
        stats: Map<String, int>.from(template['stats'] ?? {}),
        sprite: template['sprite'],
        ivs: {'hp': 31, 'atk': 31, 'def': 31, 'sp_atk': 31, 'sp_def': 31, 'spd': 31},
        evs: {'hp': 0, 'atk': 0, 'def': 0, 'sp_atk': 0, 'sp_def': 0, 'spd': 0},
        selectedMoves: [],
      );
    });

    context.read<BattleSocketService>().loadPokemonTemplateMoves(templateId);
  }

  void _removePokemonFromSlot(int index) {
    setState(() {
      _editingPokemons[index] = null;
      if (_selectedSlotIndex == index) {
        _selectedSlotIndex = null;
      }
    });
  }

  void _updateStatIV(int slotIndex, String statKey, int val) {
    setState(() {
      final pkmn = _editingPokemons[slotIndex];
      if (pkmn != null) {
        pkmn.ivs[statKey] = val;
      }
    });
  }

  void _updateStatEV(int slotIndex, String statKey, int val) {
    setState(() {
      final pkmn = _editingPokemons[slotIndex];
      if (pkmn != null) {
        // Calculate other EVs sum
        int currentSum = 0;
        pkmn.evs.forEach((key, value) {
          if (key != statKey) currentSum += value;
        });

        // Limit individual to 252, and total to 510
        int allowedVal = val.clamp(0, 252);
        if (currentSum + allowedVal > 510) {
          allowedVal = 510 - currentSum;
        }
        pkmn.evs[statKey] = allowedVal;
      }
    });
  }

  void _toggleMoveSelection(int slotIndex, Map<String, dynamic> move) {
    setState(() {
      final pkmn = _editingPokemons[slotIndex];
      if (pkmn != null) {
        final moveId = move['id'] as int;
        final alreadySelected = pkmn.selectedMoves.contains(moveId);

        if (alreadySelected) {
          pkmn.selectedMoves.remove(moveId);
        } else if (pkmn.selectedMoves.length < 4) {
          pkmn.selectedMoves.add(moveId);
        }
      }
    });
  }

  void _saveTeam(BattleSocketService socketService) {
    final name = _nameController.text.trim().isEmpty ? 'Nuevo Equipo' : _nameController.text.trim();
    final List<Map<String, dynamic>> payloadPokemons = [];

    for (final pkmn in _editingPokemons) {
      if (pkmn != null && pkmn.selectedMoves.isNotEmpty) {
        payloadPokemons.add({
          'pokemon_template_id': pkmn.templateId,
          'nickname': pkmn.nickname.trim().isEmpty ? pkmn.name : pkmn.nickname.trim(),
          'ivs': pkmn.ivs,
          'evs': pkmn.evs,
          'moves': pkmn.selectedMoves,
        });
      }
    }

    if (payloadPokemons.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    socketService.createTeam(name, payloadPokemons, teamId: _selectedTeamId);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final socketService = context.watch<BattleSocketService>();
    final profile = socketService.currentPlayer;

    final loadedDetails = socketService.loadedTeamDetails;
    if (loadedDetails != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        socketService.clearLoadedTeamDetails();
      });
      _selectedTeamId = loadedDetails['team_id'] as int?;
      _nameController.text = loadedDetails['name'] ?? '';
      final pokemons = loadedDetails['pokemons'] as List? ?? [];
      for (int i = 0; i < 6; i++) {
        if (i < pokemons.length) {
          final p = Map<String, dynamic>.from(pokemons[i] as Map);
          _editingPokemons[i] = _EditingPokemon(
            templateId: p['pokemon_template_id'] as int,
            name: p['name'] ?? 'Pokémon',
            nickname: p['nickname'] ?? '',
            types: List<String>.from(p['types'] ?? []),
            stats: Map<String, int>.from(p['stats'] ?? {}),
            sprite: p['sprite'] as String?,
            ivs: Map<String, int>.from(p['ivs'] ?? {}),
            evs: Map<String, int>.from(p['evs'] ?? {}),
            selectedMoves: List<int>.from(p['selected_moves'] ?? []),
          );
          if (!socketService.templateMoves.containsKey(p['pokemon_template_id'])) {
            socketService.loadPokemonTemplateMoves(p['pokemon_template_id'] as int);
          }
        } else {
          _editingPokemons[i] = null;
        }
      }
      _isEditing = true;
      _selectedSlotIndex = 0;
    }

    final rawTeams = profile?['teams'] as List?;
    final List<Map<String, dynamic>> teams = rawTeams != null
        ? rawTeams.map((t) => Map<String, dynamic>.from(t as Map)).toList()
        : const [];

    // Automatically exit editing mode if a team was successfully created
    if (_isSaving && teams.length > _previousTeamsCount) {
      _isEditing = false;
      _isSaving = false;
    }

    if (!_isEditing) {
      return _buildTeamList(context, text, teams);
    } else {
      return _buildTeamEditor(context, text, socketService);
    }
  }

  Widget _buildTeamList(BuildContext context, TextTheme text, List<Map<String, dynamic>> teams) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Constructor de equipos',
                      style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crea, edita y organiza tus equipos para la batalla.',
                      style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _startNewTeam(teams.length),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nuevo equipo'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: teams.isEmpty
                ? Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes equipos creados',
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea un equipo personalizado haciendo clic en "Nuevo equipo" y configúralo a tu gusto.',
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceMuted,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, c) {
                      final cross = c.maxWidth > 1100 ? 3 : (c.maxWidth > 700 ? 2 : 1);
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          childAspectRatio: 1.45,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: teams.length,
                        itemBuilder: (context, i) => _TeamCard(team: teams[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamEditor(BuildContext context, TextTheme text, BattleSocketService socketService) {
    final canSave = _editingPokemons.any((p) => p != null && p.selectedMoves.isNotEmpty) && !_isSaving;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Editor Header
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isEditing = false),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre del equipo...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              if (_isSaving)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: canSave ? () => _saveTeam(socketService) : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Equipo'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: 6 Slots & Active Slot Editor
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // 6 Slots Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.6,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, idx) {
                          final pkmn = _editingPokemons[idx];
                          final isSelected = _selectedSlotIndex == idx;

                          return GestureDetector(
                            onTap: () => _selectSlot(idx),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Stack(
                                children: [
                                  if (pkmn == null)
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, color: AppColors.onSurfaceMuted, size: 20),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Espacio ${idx + 1}',
                                            style: TextStyle(
                                              color: AppColors.onSurfaceMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          // Sprite/GIF
                                          if (pkmn.sprite != null)
                                            Image.network(
                                              pkmn.sprite!,
                                              width: 48,
                                              height: 48,
                                              errorBuilder: (_, __, ___) => Icon(
                                                Icons.catching_pokemon,
                                                color: AppColors.onSurfaceMuted,
                                                size: 32,
                                              ),
                                            )
                                          else
                                            Icon(
                                              Icons.catching_pokemon,
                                              color: AppColors.onSurfaceMuted,
                                              size: 32,
                                            ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  pkmn.nickname,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                _buildCombinedTypeBadge(pkmn.types),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (pkmn != null)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: IconButton(
                                        icon: Icon(Icons.close, size: 14, color: AppColors.danger),
                                        onPressed: () => _removePokemonFromSlot(idx),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Selected Slot Customizer Panel
                      Expanded(
                        child: _buildSlotCustomizer(context, text, socketService),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Panel: Search Bar, Type Filters, and Templates List
                Expanded(
                  flex: 2,
                  child: Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: AppColors.outlineVariant),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      children: [
                        // Search text box
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar Pokémon...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          ),
                        ),
                        // Type chips scroll list
                        _buildTypeFilterRow(),
                        const Divider(height: 1),
                        // Templates list
                        Expanded(
                          child: _buildTemplateListView(socketService),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterRow() {
    const List<String> types = [
      'Normal', 'Fire', 'Water', 'Grass', 'Electric', 'Ice',
      'Fighting', 'Poison', 'Ground', 'Flying', 'Psychic', 'Bug',
      'Rock', 'Ghost', 'Dragon', 'Dark', 'Steel', 'Fairy'
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        itemBuilder: (context, idx) {
          final type = types[idx];
          final isSelected = _selectedTypeFilter == type;
          final color = PokemonTypeIcons.getColor(type);

          return Padding(
            padding: EdgeInsets.only(
              left: idx == 0 ? 16 : 4,
              right: idx == types.length - 1 ? 16 : 4,
            ),
            child: Tooltip(
              message: type,
              child: Material(
                color: isSelected ? color : color.withValues(alpha: 0.15),
                shape: CircleBorder(
                  side: BorderSide(
                    color: isSelected ? Colors.white : color.withValues(alpha: 0.4),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTypeFilter = isSelected ? null : type;
                    });
                  },
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: PokemonTypeIcons.buildSvgIcon(
                        type,
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTemplateListView(BattleSocketService socketService) {
    // Filter templates locally
    final filtered = socketService.pokemonTemplates.where((t) {
      final name = (t['name'] as String? ?? '').toLowerCase();
      final types = List<String>.from(t['types'] ?? []);

      final matchesQuery = name.contains(_searchQuery);
      final matchesType = _selectedTypeFilter == null ||
          types.any((type) => type.toLowerCase() == _selectedTypeFilter!.toLowerCase());

      return matchesQuery && matchesType;
    }).toList();

    if (socketService.isLoadingTemplates && socketService.pokemonTemplates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando Pokémon desde la PokéAPI...'),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No se encontraron Pokémon con los filtros actuales.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final t = filtered[index];
        final name = t['name'] ?? 'Pokémon';
        final types = List<String>.from(t['types'] ?? []);
        final stats = Map<String, dynamic>.from(t['stats'] ?? {});
        final gifUrl = t['sprite'] as String?;

        // Calculate BST
        int bst = 0;
        stats.forEach((_, val) => bst += (val as int? ?? 0));

        return ListTile(
          onTap: () => _addPokemonToSelectedSlot(t),
          leading: gifUrl != null
              ? Image.network(
                  gifUrl,
                  width: 44,
                  height: 44,
                  errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon, color: AppColors.onSurfaceMuted, size: 28),
                )
              : Icon(Icons.catching_pokemon, color: AppColors.onSurfaceMuted, size: 28),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              _buildCombinedTypeBadge(types),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  'HP:${stats['hp']} A:${stats['atk']} D:${stats['def']} SA:${stats['sp_atk']} SD:${stats['sp_def']} S:${stats['spd']}',
                  style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BST: $bst',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotCustomizer(BuildContext context, TextTheme text, BattleSocketService socketService) {
    if (_selectedSlotIndex == null) {
      return Center(
        child: Text(
          'Selecciona un espacio arriba para agregar y configurar un Pokémon.',
          style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 14),
        ),
      );
    }

    final idx = _selectedSlotIndex!;
    final pkmn = _editingPokemons[idx];

    if (pkmn == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_right_alt, color: AppColors.primary, size: 36),
            const SizedBox(height: 8),
            Text(
              'Selecciona un Pokémon de la lista a la derecha para rellenar este espacio.',
              style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Load available moves for template
    final moves = socketService.templateMoves[pkmn.templateId] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nickname Customizer
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Apodo (Nickname)',
                      hintText: pkmn.name,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: const OutlineInputBorder(),
                    ),
                    maxLength: 10,
                    controller: TextEditingController(text: pkmn.nickname)..selection = TextSelection.collapsed(offset: pkmn.nickname.length),
                    onChanged: (val) {
                      setState(() {
                        pkmn.nickname = val;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // IVs & EVs Editor
            Text('Estadísticas Individuales (IVs) y de Esfuerzo (EVs)', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStatsSlidersTable(pkmn),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Moves selection
            Row(
              children: [
                Text('Movimientos Seleccionados (${pkmn.selectedMoves.length}/4)', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (pkmn.selectedMoves.isEmpty) ...[
                  const SizedBox(width: 8),
                  Text('(Agrega al menos 1 para poder guardar)', style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (socketService.isLoadingMoves)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else
              _buildMovesGrid(pkmn, moves),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSlidersTable(_EditingPokemon pkmn) {
    final statKeys = ['hp', 'atk', 'def', 'sp_atk', 'sp_def', 'spd'];
    final statNames = {
      'hp': 'PS (HP)',
      'atk': 'Ataque',
      'def': 'Defensa',
      'sp_atk': 'At. Esp.',
      'sp_def': 'Def. Esp.',
      'spd': 'Velocidad',
    };

    // Calculate total EVs
    int evSum = 0;
    pkmn.evs.forEach((_, val) => evSum += val);

    return Column(
      children: [
        ...statKeys.map((key) {
          final base = pkmn.stats[key] ?? 0;
          final iv = pkmn.ivs[key] ?? 31;
          final ev = pkmn.evs[key] ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    statNames[key]!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  'Base: $base',
                  style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 11),
                ),
                const SizedBox(width: 12),
                // IV field
                Expanded(
                  child: Row(
                    children: [
                      const Text('IV: ', style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Slider(
                          value: iv.toDouble(),
                          min: 0,
                          max: 31,
                          divisions: 31,
                          label: iv.toString(),
                          onChanged: (val) => _updateStatIV(_selectedSlotIndex!, key, val.toInt()),
                        ),
                      ),
                      Text(iv.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // EV field
                Expanded(
                  child: Row(
                    children: [
                      const Text('EV: ', style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Slider(
                          value: ev.toDouble(),
                          min: 0,
                          max: 252,
                          divisions: 252 ~/ 4,
                          label: ev.toString(),
                          onChanged: (val) => _updateStatEV(_selectedSlotIndex!, key, val.toInt()),
                        ),
                      ),
                      Text(ev.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Total EVs: $evSum / 510',
              style: TextStyle(
                color: evSum >= 510 ? AppColors.warning : AppColors.onSurfaceMuted,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMovesGrid(_EditingPokemon pkmn, List<Map<String, dynamic>> moves) {
    if (moves.isEmpty) {
      return const Text(
        'No hay movimientos disponibles para este Pokémon.',
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            childAspectRatio: 2.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: moves.length,
          itemBuilder: (context, index) {
            final move = moves[index];
            final name = move['name'] ?? 'Movimiento';
            final moveId = move['id'] as int;
            final isSelected = pkmn.selectedMoves.contains(moveId);
            final type = move['type'] as String? ?? 'Normal';
            final power = move['power'] as int?;
            final accuracy = move['accuracy'] as int?;
            final pp = move['pp'] as int? ?? 0;
            final category = move['category'] as String? ?? 'Physical';

            final typeColor = PokemonTypeIcons.getColor(type);

            return Material(
              color: isSelected
                  ? typeColor.withValues(alpha: 0.15)
                  : AppColors.surfaceHigh,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isSelected ? typeColor : AppColors.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: InkWell(
                onTap: () => _toggleMoveSelection(_selectedSlotIndex!, move),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, size: 14, color: typeColor),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          PokemonTypeIcons.buildTypeBadge(type, fontSize: 8),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: TextStyle(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          SvgPicture.string(
                            _swordSvg,
                            width: 8,
                            height: 8,
                            colorFilter: ColorFilter.mode(
                              AppColors.onSurfaceMuted,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            power != null && power > 0 ? '$power' : '—',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.string(
                            _bullseyeSvg,
                            width: 8,
                            height: 8,
                            colorFilter: ColorFilter.mode(
                              AppColors.onSurfaceMuted,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            accuracy != null ? '$accuracy' : '—',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'PP: $pp',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCombinedTypeBadge(List<String> types) {
    if (types.isEmpty) return const SizedBox.shrink();

    final c1 = PokemonTypeIcons.getColor(types[0]);
    final c2 = types.length > 1 ? PokemonTypeIcons.getColor(types[1]) : c1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c1.withValues(alpha: 0.15),
            c2.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.lerp(c1, c2, 0.5)!.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PokemonTypeIcons.buildSvgIcon(types[0], color: c1, size: 12),
          if (types.length > 1) ...[
            const SizedBox(width: 4),
            PokemonTypeIcons.buildSvgIcon(types[1], color: c2, size: 12),
          ],
          const SizedBox(width: 6),
          Text(
            types.join(' / ').toUpperCase(),
            style: TextStyle(
              color: Color.lerp(c1, c2, 0.5)!,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditingPokemon {
  final int templateId;
  final String name;
  String nickname;
  final List<String> types;
  final Map<String, int> stats;
  final String? sprite;
  final Map<String, int> ivs;
  final Map<String, int> evs;
  final List<int> selectedMoves; // List of selected move IDs

  _EditingPokemon({
    required this.templateId,
    required this.name,
    required this.nickname,
    required this.types,
    required this.stats,
    this.sprite,
    required this.ivs,
    required this.evs,
    required this.selectedMoves,
  });
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  const _TeamCard({required this.team});

  List<Color> _getPokemonColors(List<String> types) {
    if (types.isEmpty) return [AppColors.primary];
    return types.map((t) => PokemonTypeIcons.getColor(t)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Safely extract pokemons
    final rawPokemons = team['pokemons'] as List?;
    final pokemons = rawPokemons != null
        ? rawPokemons.map((p) => Map<String, dynamic>.from(p as Map)).toList()
        : const <Map<String, dynamic>>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.shield, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team['name'] ?? 'Equipo', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        team['description'] ?? '',
                        style: text.bodySmall?.copyWith(color: AppColors.onSurfaceMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final socket = context.read<BattleSocketService>();
                    final id = team['id'] as int?;
                    if (id != null) {
                      socket.getTeamDetails(id);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  onPressed: () {
                    final id = team['id'] as int?;
                    if (id == null) return;
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('¿Eliminar equipo?'),
                        content: Text('¿Estás seguro de que deseas eliminar el equipo "${team['name']}"? Esta acción no se puede deshacer.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              context.read<BattleSocketService>().deleteTeam(id);
                            },
                            child: Text('Eliminar', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pokemons.map((p) {
                    final rawTypes = p['types'] as List? ?? [];
                    final types = rawTypes.cast<String>();
                    final colors = _getPokemonColors(types);
                    final c1 = colors[0];
                    final c2 = colors.length > 1 ? colors[1] : c1;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            c1.withValues(alpha: 0.14),
                            c2.withValues(alpha: 0.14),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color.lerp(c1, c2, 0.5)!.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (types.isNotEmpty) ...[
                            PokemonTypeIcons.buildSvgIcon(types[0], color: c1, size: 14),
                            if (types.length > 1) ...[
                              const SizedBox(width: 4),
                              PokemonTypeIcons.buildSvgIcon(types[1], color: c2, size: 14),
                            ],
                          ] else ...[
                            Icon(Icons.catching_pokemon, color: c1, size: 14),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            p['name'] ?? 'Pokémon',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const String _swordSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polyline points="14.5 17.5 3 6 3 3 6 3 17.5 14.5" />
  <line x1="13" y1="19" x2="19" y2="13" />
  <line x1="16" y1="16" x2="20" y2="20" />
  <line x1="19" y1="21" x2="21" y2="19" />
</svg>
''';

const String _bullseyeSvg = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10" />
  <circle cx="12" cy="12" r="6" />
  <circle cx="12" cy="12" r="2" fill="currentColor" />
</svg>
''';


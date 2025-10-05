import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeViewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PokeHomePage(),
    );
  }
}

class PokeHomePage extends StatefulWidget {
  const PokeHomePage({super.key});

  @override
  State<PokeHomePage> createState() => _PokeHomePageState();
}

enum ViewState { idle, loading, success, error }

class Pokemon {
  final int id;
  final String name;
  final String spriteUrl;

  Pokemon({required this.id, required this.name, required this.spriteUrl});

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final sprites = json['sprites'] as Map<String, dynamic>? ?? {};
    // preferred front_default sprite
    final sprite = sprites['front_default'] as String? ?? '';
    return Pokemon(
      id: json['id'] as int,
      name: (json['name'] as String).replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase()),
      spriteUrl: sprite,
    );
  }
}

class _PokeHomePageState extends State<PokeHomePage> {
  final TextEditingController _controller = TextEditingController();
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  Pokemon? _pokemon;

  static const int minId = 1;
  static const int maxId = 151;

  Future<void> _fetchPokemon(int id) async {
    setState(() {
      _state = ViewState.loading;
      _errorMessage = null;
      _pokemon = null;
    });

    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/$id');
    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final p = Pokemon.fromJson(data);
        setState(() {
          _pokemon = p;
          _state = ViewState.success;
        });
      } else if (resp.statusCode == 404) {
        setState(() {
          _errorMessage = 'No Pokémon found for id $id.';
          _state = ViewState.error;
        });
      } else {
        setState(() {
          _errorMessage = 'Server returned ${resp.statusCode}';
          _state = ViewState.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _state = ViewState.error;
      });
    }
  }

  void _onSearchPressed() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a Pokédex number (1-151).';
        _state = ViewState.error;
      });
      return;
    }
    final id = int.tryParse(text);
    if (id == null || id < minId || id > maxId) {
      setState(() {
        _errorMessage = 'Enter a whole number between $minId and $maxId.';
        _state = ViewState.error;
      });
      return;
    }
    _fetchPokemon(id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pokédex number (1-151)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _onSearchPressed(),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _onSearchPressed,
            child: const Text('Show'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'An unknown error occurred.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // retry last id if available, otherwise clear error
                    if (_pokemon != null) {
                      _fetchPokemon(_pokemon!.id);
                    } else {
                      setState(() => _state = ViewState.idle);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                )
              ],
            ),
          ),
        );
      case ViewState.success:
        final p = _pokemon!;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.spriteUrl.isNotEmpty)
                      Image.network(p.spriteUrl, width: 150, height: 150, fit: BoxFit.contain, semanticLabel: '${p.name} sprite'),
                    const SizedBox(height: 12),
                    Text(
                      '${p.name}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dex #${p.id}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _fetchPokemon(p.id),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      case ViewState.idle:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.catching_pokemon, size: 72, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'Enter a Gen-1 Pokédex number (1-151) and press Show to load a Pokémon.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PokeViewer')),
      body: SafeArea(
        child: Column(
          children: [
            _buildControls(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}

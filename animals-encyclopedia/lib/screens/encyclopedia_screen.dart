import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animals_service.dart';
import 'animal_detail_screen.dart';

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Animal> _animals = <Animal>[];
  List<Animal> _filteredAnimals = <Animal>[];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _animals = AnimalsService.getAllAnimals();
    _filteredAnimals = List<Animal>.from(_animals);
    _searchController.addListener(_filterAnimals);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAnimals() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredAnimals = _animals.where((animal) {
        final categoryOk = _selectedCategory == 'All' || animal.category == _selectedCategory;
        final searchOk = query.isEmpty ||
            animal.name.toLowerCase().contains(query) ||
            animal.description.toLowerCase().contains(query);
        return categoryOk && searchOk;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...AnimalsService.getCategories()];

    return Scaffold(
      appBar: AppBar(title: const Text('Animal World')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search animal...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() => _selectedCategory = category);
                        _filterAnimals();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _filteredAnimals.isEmpty
                ? const Center(child: Text('No animals found for this filter.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredAnimals.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final animal = _filteredAnimals[index];
                      return _AnimalCard(animal: animal);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AnimalDetailScreen(animal: animal)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'animal_image_${animal.id}',
                child: SizedBox(
                  width: double.infinity,
                  child: Image.asset(
                    animal.imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 640,
                    filterQuality: FilterQuality.low,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.orange.withValues(alpha: 0.12),
                      child: const Center(
                        child: Icon(Icons.pets_rounded, size: 42),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    animal.category,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

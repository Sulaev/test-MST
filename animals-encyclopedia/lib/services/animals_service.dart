import '../models/animal.dart';
import 'logger_service.dart';
import 'package:flutter/widgets.dart';

class AnimalsService {
  static const String mammals = 'Mammals';
  static const String birds = 'Birds';
  static const String marine = 'Marine';

  static final List<Animal> _animals = [
    Animal(
      id: 'lion',
      name: 'Lion',
      category: mammals,
      description: 'Lions are powerful big cats known as social hunters living in prides.',
      habitat: 'Savannas and grasslands',
      diet: 'Carnivore',
      imageUrl: 'assets/images/lion.jpg',
      soundUrl: 'sounds/lion.mp3',
      facts: const [
        'Lions can rest up to 20 hours a day.',
        'A lion roar can be heard from several kilometers away.',
        'Female lions do most of the hunting in a pride.',
      ],
    ),
    Animal(
      id: 'elephant',
      name: 'Elephant',
      category: mammals,
      description: 'Elephants are the largest land mammals and have excellent memory.',
      habitat: 'Savannas and forests',
      diet: 'Herbivore',
      imageUrl: 'assets/images/elephant.jpg',
      soundUrl: 'sounds/elephant.ogg',
      facts: const [
        'Elephants use their trunks to breathe, smell, and grab food.',
        'They communicate with low-frequency sounds.',
        'Elephants can recognize themselves in mirrors.',
      ],
    ),
    Animal(
      id: 'tiger',
      name: 'Tiger',
      category: mammals,
      description: 'Tigers are strong solitary hunters with unique stripe patterns.',
      habitat: 'Forests and mangroves',
      diet: 'Carnivore',
      imageUrl: 'assets/images/tiger.jpg',
      soundUrl: 'sounds/tiger.mp3',
      facts: const [
        'Every tiger has a unique stripe pattern.',
        'Tigers are excellent swimmers.',
        'They usually hunt alone, mostly at night.',
      ],
    ),
    Animal(
      id: 'dolphin',
      name: 'Dolphin',
      category: marine,
      description: 'Dolphins are intelligent marine mammals that use clicks to navigate.',
      habitat: 'Oceans and seas',
      diet: 'Carnivore',
      imageUrl: 'assets/images/dolphin.jpg',
      soundUrl: 'sounds/dolphin.mp3',
      facts: const [
        'Dolphins use echolocation to find prey.',
        'They are highly social and often travel in pods.',
        'Dolphins can jump several meters above water.',
      ],
    ),
    Animal(
      id: 'penguin',
      name: 'Penguin',
      category: birds,
      description: 'Penguins are flightless birds perfectly adapted for swimming in cold waters.',
      habitat: 'Southern Hemisphere coasts',
      diet: 'Carnivore',
      imageUrl: 'assets/images/penguin.jpg',
      soundUrl: 'sounds/penguin.ogg',
      facts: const [
        'Penguins use dense feathers to stay warm.',
        'They can dive deep and hold breath for minutes.',
        'Parents take turns protecting eggs and chicks.',
      ],
    ),
    Animal(
      id: 'eagle',
      name: 'Eagle',
      category: birds,
      description: 'Eagles are birds of prey with outstanding vision and strong talons.',
      habitat: 'Mountains, coasts, and open areas',
      diet: 'Carnivore',
      imageUrl: 'assets/images/eagle.jpg',
      soundUrl: 'sounds/eagle.wav',
      facts: const [
        'Eagles can spot prey from very long distances.',
        'They build large nests high on cliffs or trees.',
        'Their grip is much stronger than a human hand.',
      ],
    ),
    Animal(
      id: 'owl',
      name: 'Owl',
      category: birds,
      description: 'Owls are mostly nocturnal birds with silent flight and sharp hearing.',
      habitat: 'Forests, fields, and deserts',
      diet: 'Carnivore',
      imageUrl: 'assets/images/owl.jpg',
      soundUrl: 'sounds/owl.mp3',
      facts: const [
        'Owls can rotate their heads up to about 270 degrees.',
        'Their feathers help them fly almost silently.',
        'Many owls are active during the night.',
      ],
    ),
    Animal(
      id: 'seal',
      name: 'Seal',
      category: marine,
      description: 'Seals are marine mammals that spend time both in water and on shore.',
      habitat: 'Cold and temperate coasts',
      diet: 'Carnivore',
      imageUrl: 'assets/images/seal.jpg',
      soundUrl: 'sounds/seal.mp3',
      facts: const [
        'Seals have a thick layer of fat for insulation.',
        'They can stay underwater for a long time.',
        'Seals are fast swimmers but move slowly on land.',
      ],
    ),
  ];
  static bool _imagesPrecached = false;

  static List<Animal> getAllAnimals() {
    return List<Animal>.from(_animals);
  }

  static Future<void> ensureImagesPrecached(BuildContext context) async {
    if (_imagesPrecached) return;
    final futures = <Future<void>>[];
    for (final animal in _animals) {
      futures.add(precacheImage(AssetImage(animal.imageUrl), context));
    }
    await Future.wait(futures);
    _imagesPrecached = true;
  }

  static List<Animal> getAnimalsByCategory(String category) {
    return _animals.where((animal) => animal.category == category).toList();
  }

  static List<String> getCategories() {
    return _animals.map((animal) => animal.category).toSet().toList()..sort();
  }

  static Animal? getAnimalById(String id) {
    try {
      return _animals.firstWhere((animal) => animal.id == id);
    } catch (e) {
      LoggerService.error('Animal not found: $id', e);
      return null;
    }
  }

  static List<Animal> searchAnimals(String query) {
    final lowerQuery = query.toLowerCase();
    return _animals.where((animal) {
      return animal.name.toLowerCase().contains(lowerQuery) ||
          animal.description.toLowerCase().contains(lowerQuery) ||
          animal.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

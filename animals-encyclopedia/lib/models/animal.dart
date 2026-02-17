class Animal {
  final String id;
  final String name;
  final String category;
  final String description;
  final String habitat;
  final String diet;
  final String imageUrl;
  final String? soundUrl;
  final List<String> facts;

  Animal({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.habitat,
    required this.diet,
    required this.imageUrl,
    this.soundUrl,
    required this.facts,
  });

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      habitat: json['habitat'] as String,
      diet: json['diet'] as String,
      imageUrl: (json['imageUrl'] as String?) ?? '',
      soundUrl: json['soundUrl'] as String?,
      facts: List<String>.from(json['facts'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'habitat': habitat,
      'diet': diet,
      'imageUrl': imageUrl,
      'soundUrl': soundUrl,
      'facts': facts,
    };
  }
}

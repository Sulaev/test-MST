import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BreathingPractice {
  BreathingPractice({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.inhaleSeconds,
    required this.exhaleSeconds,
    this.iconAssetPath = 'assets/routine/yoga-mat.png',
  });

  final String title;
  final String description;
  final int durationMinutes;
  final int inhaleSeconds;
  final int exhaleSeconds;
  final String iconAssetPath;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'inhaleSeconds': inhaleSeconds,
        'exhaleSeconds': exhaleSeconds,
        'iconAssetPath': iconAssetPath,
      };

  factory BreathingPractice.fromJson(Map<String, dynamic> json) {
    int parseInt(Object? raw, int fallback) {
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? fallback;
    }

    return BreathingPractice(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      durationMinutes: parseInt(json['durationMinutes'], 2),
      inhaleSeconds: parseInt(json['inhaleSeconds'], 4),
      exhaleSeconds: parseInt(json['exhaleSeconds'], 6),
      iconAssetPath: (json['iconAssetPath'] ?? 'assets/routine/yoga-mat.png').toString(),
    );
  }
}

class SavedBreathingEntry {
  SavedBreathingEntry({
    required this.id,
    required this.createdAt,
    required this.practice,
  });

  final String id;
  final DateTime createdAt;
  final BreathingPractice practice;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'practice': practice.toJson(),
      };

  factory SavedBreathingEntry.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = (json['createdAt'] ?? '').toString();
    final createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now().toUtc();
    final practiceJson = json['practice'];
    final practice = practiceJson is Map
        ? BreathingPractice.fromJson(Map<String, dynamic>.from(practiceJson))
        : BreathingPractice(
            title: 'Breathing',
            description: 'Calm your mind and body',
            durationMinutes: 2,
            inhaleSeconds: 4,
            exhaleSeconds: 6,
          );
    return SavedBreathingEntry(
      id: (json['id'] ?? '').toString(),
      createdAt: createdAt,
      practice: practice,
    );
  }
}

class BreathingLibraryService {
  BreathingLibraryService._();

  static final BreathingLibraryService instance = BreathingLibraryService._();

  static const String _storageKey = 'saved_breathing_practices_v1';

  static final List<BreathingPractice> defaults = <BreathingPractice>[
    BreathingPractice(
      title: 'RELAX',
      description: 'Calm your mind and body',
      durationMinutes: 2,
      inhaleSeconds: 4,
      exhaleSeconds: 6,
    ),
    BreathingPractice(
      title: 'FOCUS',
      description: 'Steady breath for better concentration',
      durationMinutes: 3,
      inhaleSeconds: 4,
      exhaleSeconds: 4,
    ),
    BreathingPractice(
      title: 'UNWIND',
      description: 'Slow evening breathing for relaxation',
      durationMinutes: 3,
      inhaleSeconds: 4,
      exhaleSeconds: 7,
    ),
  ];

  Future<List<SavedBreathingEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return <SavedBreathingEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <SavedBreathingEntry>[];
      final list = decoded
          .whereType<Map>()
          .map((e) => SavedBreathingEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return <SavedBreathingEntry>[];
    }
  }

  Future<bool> isSavedById(String id) async {
    final list = await getAll();
    return list.any((e) => e.id == id);
  }

  String buildId(BreathingPractice practice) {
    final raw = [
      practice.title.trim(),
      practice.description.trim(),
      practice.durationMinutes.toString(),
      practice.inhaleSeconds.toString(),
      practice.exhaleSeconds.toString(),
    ].join('|');
    return base64UrlEncode(utf8.encode(raw));
  }

  Future<bool> save(BreathingPractice practice) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    final id = buildId(practice);
    if (list.any((e) => e.id == id)) return false;
    list.insert(
      0,
      SavedBreathingEntry(
        id: id,
        createdAt: DateTime.now().toUtc(),
        practice: practice,
      ),
    );
    await prefs.setString(
      _storageKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    return true;
  }

  Future<bool> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    final before = list.length;
    list.removeWhere((e) => e.id == id);
    if (list.length == before) return false;
    await prefs.setString(
      _storageKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    return true;
  }
}


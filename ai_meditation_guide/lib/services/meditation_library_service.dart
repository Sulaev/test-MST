import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';

class SavedMeditationEntry {
  SavedMeditationEntry({
    required this.id,
    required this.createdAt,
    required this.meditation,
  });

  final String id;
  final DateTime createdAt;
  final GeneratedMeditation meditation;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'meditation': meditation.toJson(),
      };

  factory SavedMeditationEntry.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = (json['createdAt'] ?? '').toString();
    final createdAt =
        DateTime.tryParse(createdAtRaw) ?? DateTime.now().toUtc();
    final meditationJson = json['meditation'];
    final meditation = meditationJson is Map
        ? GeneratedMeditation.fromJson(
            Map<String, dynamic>.from(meditationJson),
          )
        : GeneratedMeditation(
            goal: MeditationGoal.reduceStress,
            title: 'Meditation',
            description: '',
            durationMinutes: 2,
            script: '',
          );
    return SavedMeditationEntry(
      id: (json['id'] ?? '').toString(),
      createdAt: createdAt,
      meditation: meditation,
    );
  }
}

class MeditationLibraryService {
  MeditationLibraryService._();

  static final MeditationLibraryService instance = MeditationLibraryService._();

  static const String _storageKey = 'saved_meditations_v1';

  Future<List<SavedMeditationEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return <SavedMeditationEntry>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <SavedMeditationEntry>[];
      final list = decoded
          .whereType<Map>()
          .map(
            (e) => SavedMeditationEntry.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return <SavedMeditationEntry>[];
    }
  }

  Future<bool> isSavedById(String id) async {
    final list = await getAll();
    return list.any((e) => e.id == id);
  }

  String buildId(GeneratedMeditation meditation) {
    final raw = [
      meditation.goal.name,
      meditation.durationMinutes.toString(),
      meditation.title.trim(),
      meditation.script.trim(),
    ].join('|');
    return base64UrlEncode(utf8.encode(raw));
  }

  Future<bool> save(GeneratedMeditation meditation) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll();
    final id = buildId(meditation);
    if (list.any((e) => e.id == id)) return false;
    list.insert(
      0,
      SavedMeditationEntry(
        id: id,
        createdAt: DateTime.now().toUtc(),
        meditation: meditation,
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


import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_item.dart';
import '../models/task_item.dart';
import 'logger_service.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _notesKey = 'notes';
  static const String _focusMinutesKey = 'focus_minutes';
  static const String _focusSessionsKey = 'focus_sessions';

  static Future<List<TaskItem>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_tasksKey) ?? <String>[];
      return raw
          .map((e) => TaskItem.fromMap(jsonDecode(e) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to load tasks', e);
      return <TaskItem>[];
    }
  }

  static Future<void> saveTasks(List<TaskItem> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = tasks.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList(_tasksKey, raw);
    } catch (e) {
      LoggerService.error('Failed to save tasks', e);
    }
  }

  static Future<List<NoteItem>> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_notesKey) ?? <String>[];
      return raw
          .map((e) => NoteItem.fromMap(jsonDecode(e) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggerService.error('Failed to load notes', e);
      return <NoteItem>[];
    }
  }

  static Future<void> saveNotes(List<NoteItem> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = notes.map((e) => jsonEncode(e.toMap())).toList();
      await prefs.setStringList(_notesKey, raw);
    } catch (e) {
      LoggerService.error('Failed to save notes', e);
    }
  }

  static Future<int> loadFocusMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_focusMinutesKey) ?? 25;
  }

  static Future<void> saveFocusMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_focusMinutesKey, minutes);
  }

  static Future<int> loadCompletedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_focusSessionsKey) ?? 0;
  }

  static Future<void> saveCompletedSessions(int sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_focusSessionsKey, sessions);
  }
}

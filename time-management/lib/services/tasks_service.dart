import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

class TasksService {
  static const String _keyTasks = 'tasks_list';

  static Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_keyTasks);

      if (tasksJson == null) {
        return <Map<String, dynamic>>[];
      }

      final List<dynamic> tasksList = json.decode(tasksJson) as List<dynamic>;
      return tasksList
          .map((task) => Map<String, dynamic>.from(task as Map))
          .toList();
    } catch (e) {
      LoggerService.error('Error loading tasks', e);
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = json.encode(tasks);
      await prefs.setString(_keyTasks, tasksJson);
      LoggerService.info('Tasks saved: ');
    } catch (e) {
      LoggerService.error('Error saving tasks', e);
      rethrow;
    }
  }

  static Future<void> addTask(Map<String, dynamic> task) async {
    try {
      final tasks = await getTasks();
      final now = DateTime.now();
      final normalizedTask = <String, dynamic>{
        ...task,
        'id': now.microsecondsSinceEpoch.toString(),
        'createdAt': now.toIso8601String(),
        'completed': task['completed'] ?? false,
        'completedAt': task['completedAt'],
        'priority': task['priority'] ?? 'medium',
        'dueDate': task['dueDate'],
      };

      tasks.add(normalizedTask);
      await saveTasks(tasks);
      LoggerService.info('Task added: ');
    } catch (e) {
      LoggerService.error('Error adding task', e);
      rethrow;
    }
  }

  static Future<void> updateTask(String taskId, Map<String, dynamic> updatedTask) async {
    try {
      final tasks = await getTasks();
      final index = tasks.indexWhere((task) => task['id'] == taskId);

      if (index != -1) {
        tasks[index] = {...tasks[index], ...updatedTask};
        await saveTasks(tasks);
        LoggerService.info('Task updated: ');
      }
    } catch (e) {
      LoggerService.error('Error updating task', e);
      rethrow;
    }
  }

  static Future<void> deleteTask(String taskId) async {
    try {
      final tasks = await getTasks();
      tasks.removeWhere((task) => task['id'] == taskId);
      await saveTasks(tasks);
      LoggerService.info('Task deleted: ');
    } catch (e) {
      LoggerService.error('Error deleting task', e);
      rethrow;
    }
  }
}

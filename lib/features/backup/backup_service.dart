import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static Future<void> createAndShareBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> backupData = {};

      for (String key in keys) {
        backupData[key] = prefs.get(key);
      }

      final String jsonContent = json.encode(backupData);
      final directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/moka_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(filePath);

      await file.writeAsString(jsonContent);

      await Share.shareXFiles([XFile(filePath)], text: 'نسخة احتياطية لبيانات مغسلة Moka');
    } catch (e) {
      print('Backup error: $e');
    }
  }

  static Future<void> restoreBackup(File file) async {
    try {
      final String content = await file.readAsString();
      final Map<String, dynamic> data = json.decode(content);
      final prefs = await SharedPreferences.getInstance();

      for (var entry in data.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        } else if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value);
        } else if (entry.value is double) {
          await prefs.setDouble(entry.key, entry.value);
        } else if (entry.value is List<String>) {
          await prefs.setStringList(entry.key, entry.value);
        }
      }
    } catch (e) {
      print('Restore error: $e');
    }
  }
}

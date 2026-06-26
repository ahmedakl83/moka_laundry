import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class BackupService {
  static final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static Future<void> createAndShareBackup() async {
    try {
      final file = await _generateBackupFile();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'نسخة احتياطية لبيانات مغسلة Moka - مشاركة يدوية'
      );
    } catch (e) {
      print('Backup share error: $e');
    }
  }

  static Future<File> _generateBackupFile() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> backupData = {};

    for (String key in keys) {
      backupData[key] = prefs.get(key);
    }

    final String jsonContent = json.encode(backupData);
    final directory = await getTemporaryDirectory();
    final now = DateTime.now();
    final String fileName = 'moka_backup_${DateFormat('yyyy_MM_dd_HH_mm_ss').format(now)}.json';
    final file = File('${directory.path}/$fileName');

    return await file.writeAsString(jsonContent);
  }

  static Future<bool> uploadToGoogleDrive() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final file = await _generateBackupFile();
      final now = DateTime.now();
      final String folderName = DateFormat('yyyy_MM').format(now);

      String? rootFolderId = await _getFolderId(driveApi, 'Moka_Backups');
      if (rootFolderId == null) {
        rootFolderId = await _createFolder(driveApi, 'Moka_Backups');
      }

      String? monthFolderId = await _getFolderId(driveApi, folderName, parentId: rootFolderId);
      if (monthFolderId == null) {
        monthFolderId = await _createFolder(driveApi, folderName, parentId: rootFolderId);
      }

      final driveFile = drive.File();
      driveFile.name = file.path.split('/').last;
      driveFile.parents = [monthFolderId!];

      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      return true;
    } catch (e) {
      print('Google Drive Upload error: $e');
      return false;
    }
  }

  static Future<String?> _getFolderId(drive.DriveApi api, String name, {String? parentId}) async {
    String query = "name = '$name' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    if (parentId != null) {
      query += " and '$parentId' in parents";
    }

    final list = await api.files.list(q: query);
    if (list.files != null && list.files!.isNotEmpty) {
      return list.files!.first.id;
    }
    return null;
  }

  static Future<String?> _createFolder(drive.DriveApi api, String name, {String? parentId}) async {
    final folder = drive.File();
    folder.name = name;
    folder.mimeType = 'application/vnd.google-apps.folder';
    if (parentId != null) {
      folder.parents = [parentId];
    }

    final created = await api.files.create(folder);
    return created.id;
  }

  static Future<bool> pickAndRestoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await restoreBackup(file);
        return true;
      }
      return false;
    } catch (e) {
      print('Pick and restore error: $e');
      return false;
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
        } else if (entry.value is List) {
          final List<String> stringList = List<String>.from(entry.value.map((e) => e.toString()));
          await prefs.setStringList(entry.key, stringList);
        }
      }
    } catch (e) {
      print('Restore error: $e');
      rethrow;
    }
  }
}

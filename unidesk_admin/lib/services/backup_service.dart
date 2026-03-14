import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:archive/archive.dart';
import 'dart:html' as html;

class BackupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> exportAllData() async {
    try {
      final List<String> collections = ['users', 'tickets', 'notifications'];
      final Map<String, dynamic> exportData = {};

      for (String collectionName in collections) {
        final QuerySnapshot snapshot = await _firestore.collection(collectionName).get();
        final List<Map<String, dynamic>> docs = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['_id'] = doc.id; // Store official ID
          return _processDataForExport(data);
        }).toList();
        exportData[collectionName] = docs;
      }

      final String jsonString = jsonEncode(exportData);
      final List<int> jsonBytes = utf8.encode(jsonString);

      final Archive archive = Archive();
      archive.addFile(ArchiveFile('unidesk_backup_${DateTime.now().millisecondsSinceEpoch}.json', jsonBytes.length, jsonBytes));

      final List<int>? zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) throw Exception('Zip encoding failed');

      _downloadFile(Uint8List.fromList(zipBytes), 'unidesk_backup_${DateTime.now().millisecondsSinceEpoch}.zip');
    } catch (e) {
      rethrow;
    }
  }

  static Map<String, dynamic> _processDataForExport(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, {'_type': 'timestamp', 'value': value.millisecondsSinceEpoch});
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _processDataForExport(value));
      } else if (value is List) {
        return MapEntry(key, value.map((e) => e is Map<String, dynamic> ? _processDataForExport(e) : e).toList());
      }
      return MapEntry(key, value);
    });
  }

  static void _downloadFile(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';

class RestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> importData() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.isEmpty) return;

      final List<int> zipBytes = result.files.first.bytes!;
      final Archive archive = ZipDecoder().decodeBytes(zipBytes);

      for (ArchiveFile file in archive) {
        if (file.isFile && file.name.endsWith('.json')) {
          final String jsonString = utf8.decode(file.content as List<int>);
          final Map<String, dynamic> data = jsonDecode(jsonString);
          await _processImport(data);
          break; // Assume one json file per backup
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _processImport(Map<String, dynamic> data) async {
    final WriteBatch batch = _firestore.batch();

    for (String collectionName in data.keys) {
      final List docs = data[collectionName] as List;
      for (var docData in docs) {
        final Map<String, dynamic> processedData = _restoreDataTypes(docData as Map<String, dynamic>);
        final String? id = processedData.remove('_id');
        final DocumentReference docRef = id != null 
            ? _firestore.collection(collectionName).doc(id)
            : _firestore.collection(collectionName).doc();
        batch.set(docRef, processedData, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  static Map<String, dynamic> _restoreDataTypes(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Map<String, dynamic> && value.containsKey('_type')) {
        if (value['_type'] == 'timestamp') {
          return MapEntry(key, Timestamp.fromMillisecondsSinceEpoch(value['value'] as int));
        }
      } else if (value is Map<String, dynamic>) {
        return MapEntry(key, _restoreDataTypes(value));
      } else if (value is List) {
        return MapEntry(key, value.map((e) => e is Map<String, dynamic> ? _restoreDataTypes(e) : e).toList());
      }
      return MapEntry(key, value);
    });
  }
}

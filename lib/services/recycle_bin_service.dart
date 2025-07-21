
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class RecycleBinService {
  static const String _recycleBinFolderName = 'RecycleBin';
  static const String _restoredFilesFolderName = 'RestoredFiles';
  static const String _metadataFileName = 'recycle_metadata.json';
  static const String _restoredMetadataFileName = 'restored_metadata.json';
  
  Future<Directory> _getRecycleBinDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recycleBinDir = Directory(path.join(appDir.path, _recycleBinFolderName));
    
    if (!await recycleBinDir.exists()) {
      await recycleBinDir.create(recursive: true);
    }
    
    return recycleBinDir;
  }

  Future<Directory> _getRestoredFilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final restoredDir = Directory(path.join(appDir.path, _restoredFilesFolderName));
    
    if (!await restoredDir.exists()) {
      await restoredDir.create(recursive: true);
    }
    
    return restoredDir;
  }

  Future<File> _getRestoredMetadataFile() async {
    final restoredDir = await _getRestoredFilesDirectory();
    return File(path.join(restoredDir.path, _restoredMetadataFileName));
  }

  Future<Map<String, dynamic>> _getRestoredMetadata() async {
    final metadataFile = await _getRestoredMetadataFile();
    
    if (!await metadataFile.exists()) {
      return {};
    }
    
    try {
      final content = await metadataFile.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      print('Error reading restored metadata: $e');
      return {};
    }
  }

  Future<void> _saveRestoredMetadata(Map<String, dynamic> metadata) async {
    final metadataFile = await _getRestoredMetadataFile();
    await metadataFile.writeAsString(json.encode(metadata));
  }
  
  Future<File> _getMetadataFile() async {
    final recycleBinDir = await _getRecycleBinDirectory();
    return File(path.join(recycleBinDir.path, _metadataFileName));
  }
  
  Future<Map<String, dynamic>> _getMetadata() async {
    final metadataFile = await _getMetadataFile();
    
    if (!await metadataFile.exists()) {
      return {};
    }
    
    try {
      final content = await metadataFile.readAsString();
      return json.decode(content) as Map<String, dynamic>;
    } catch (e) {
      print('Error reading metadata: $e');
      return {};
    }
  }
  
  Future<void> _saveMetadata(Map<String, dynamic> metadata) async {
    final metadataFile = await _getMetadataFile();
    await metadataFile.writeAsString(json.encode(metadata));
  }
  
  Future<bool> moveToRecycleBin(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      final recycleBinDir = await _getRecycleBinDirectory();
      final fileName = path.basename(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';
      final newPath = path.join(recycleBinDir.path, newFileName);
      
      // Move file to recycle bin
      await file.copy(newPath);
      await file.delete();
      
      // Update metadata
      final metadata = await _getMetadata();
      metadata[newFileName] = {
        'originalPath': filePath,
        'originalName': fileName,
        'deletedAt': timestamp,
        'size': await File(newPath).length(),
      };
      
      await _saveMetadata(metadata);
      return true;
    } catch (e) {
      print('Error moving file to recycle bin: $e');
      return false;
    }
  }
  
  Future<List<RecycleBinItem>> getRecycleBinItems() async {
    try {
      final metadata = await _getMetadata();
      final items = <RecycleBinItem>[];
      final recycleBinDir = await _getRecycleBinDirectory();
      
      for (final entry in metadata.entries) {
        final fileName = entry.key;
        final info = entry.value as Map<String, dynamic>;
        final filePath = path.join(recycleBinDir.path, fileName);
        
        if (await File(filePath).exists()) {
          items.add(RecycleBinItem(
            id: fileName,
            originalPath: info['originalPath'] as String,
            originalName: info['originalName'] as String,
            deletedAt: DateTime.fromMillisecondsSinceEpoch(info['deletedAt'] as int),
            size: info['size'] as int,
            currentPath: filePath,
          ));
        }
      }
      
      // Sort by deletion date (most recent first)
      items.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
      return items;
    } catch (e) {
      print('Error getting recycle bin items: $e');
      return [];
    }
  }
  
  Future<bool> restoreFromRecycleBin(String itemId) async {
    try {
      final metadata = await _getMetadata();
      final itemInfo = metadata[itemId];
      
      if (itemInfo == null) {
        return false;
      }
      
      final recycleBinDir = await _getRecycleBinDirectory();
      final currentPath = path.join(recycleBinDir.path, itemId);
      final originalName = itemInfo['originalName'] as String;
      
      final currentFile = File(currentPath);
      if (!await currentFile.exists()) {
        return false;
      }
      
      // Move to restored files folder instead of original location
      final restoredDir = await _getRestoredFilesDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final restoredFileName = '${timestamp}_$originalName';
      final restoredPath = path.join(restoredDir.path, restoredFileName);
      
      // Restore the file to restored files folder
      await currentFile.copy(restoredPath);
      await currentFile.delete();
      
      // Add to restored files metadata
      final restoredMetadata = await _getRestoredMetadata();
      restoredMetadata[restoredFileName] = {
        'originalPath': itemInfo['originalPath'],
        'originalName': originalName,
        'restoredAt': timestamp,
        'size': itemInfo['size'],
        'deletedAt': itemInfo['deletedAt'],
      };
      await _saveRestoredMetadata(restoredMetadata);
      
      // Remove from recycle bin metadata
      metadata.remove(itemId);
      await _saveMetadata(metadata);
      
      return true;
    } catch (e) {
      print('Error restoring file from recycle bin: $e');
      return false;
    }
  }
  
  Future<bool> permanentlyDelete(String itemId) async {
    try {
      final metadata = await _getMetadata();
      
      if (!metadata.containsKey(itemId)) {
        return false;
      }
      
      final recycleBinDir = await _getRecycleBinDirectory();
      final filePath = path.join(recycleBinDir.path, itemId);
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from metadata
      metadata.remove(itemId);
      await _saveMetadata(metadata);
      
      return true;
    } catch (e) {
      print('Error permanently deleting file: $e');
      return false;
    }
  }
  
  Future<void> emptyRecycleBin() async {
    try {
      final recycleBinDir = await _getRecycleBinDirectory();
      
      // Delete all files in recycle bin
      await for (final entity in recycleBinDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
      
      // Clear metadata
      await _saveMetadata({});
    } catch (e) {
      print('Error emptying recycle bin: $e');
    }
  }
  
  Future<int> getRecycleBinSize() async {
    try {
      final items = await getRecycleBinItems();
      return items.fold<int>(0, (sum, item) => sum + item.size);
    } catch (e) {
      print('Error calculating recycle bin size: $e');
      return 0;
    }
  }
  
  Future<List<RestoredFileItem>> getRestoredFiles() async {
    try {
      final metadata = await _getRestoredMetadata();
      final items = <RestoredFileItem>[];
      final restoredDir = await _getRestoredFilesDirectory();
      
      for (final entry in metadata.entries) {
        final fileName = entry.key;
        final info = entry.value as Map<String, dynamic>;
        final filePath = path.join(restoredDir.path, fileName);
        
        if (await File(filePath).exists()) {
          items.add(RestoredFileItem(
            id: fileName,
            originalPath: info['originalPath'] as String,
            originalName: info['originalName'] as String,
            restoredAt: DateTime.fromMillisecondsSinceEpoch(info['restoredAt'] as int),
            deletedAt: DateTime.fromMillisecondsSinceEpoch(info['deletedAt'] as int),
            size: info['size'] as int,
            currentPath: filePath,
          ));
        }
      }
      
      // Sort by restoration date (most recent first)
      items.sort((a, b) => b.restoredAt.compareTo(a.restoredAt));
      return items;
    } catch (e) {
      print('Error getting restored files: $e');
      return [];
    }
  }

  Future<bool> moveToOriginalLocation(String itemId) async {
    try {
      final metadata = await _getRestoredMetadata();
      final itemInfo = metadata[itemId];
      
      if (itemInfo == null) {
        return false;
      }
      
      final restoredDir = await _getRestoredFilesDirectory();
      final currentPath = path.join(restoredDir.path, itemId);
      final originalPath = itemInfo['originalPath'] as String;
      
      final currentFile = File(currentPath);
      if (!await currentFile.exists()) {
        return false;
      }
      
      // Ensure the original directory exists
      final originalDir = Directory(path.dirname(originalPath));
      if (!await originalDir.exists()) {
        await originalDir.create(recursive: true);
      }
      
      // Check if a file already exists at the original location
      var targetPath = originalPath;
      var counter = 1;
      while (await File(targetPath).exists()) {
        final dir = path.dirname(originalPath);
        final name = path.basenameWithoutExtension(originalPath);
        final ext = path.extension(originalPath);
        targetPath = path.join(dir, '${name}_restored_$counter$ext');
        counter++;
      }
      
      // Move to original location
      await currentFile.copy(targetPath);
      await currentFile.delete();
      
      // Remove from restored metadata
      metadata.remove(itemId);
      await _saveRestoredMetadata(metadata);
      
      return true;
    } catch (e) {
      print('Error moving file to original location: $e');
      return false;
    }
  }

  Future<bool> deleteRestoredFile(String itemId) async {
    try {
      final metadata = await _getRestoredMetadata();
      
      if (!metadata.containsKey(itemId)) {
        return false;
      }
      
      final restoredDir = await _getRestoredFilesDirectory();
      final filePath = path.join(restoredDir.path, itemId);
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from metadata
      metadata.remove(itemId);
      await _saveRestoredMetadata(metadata);
      
      return true;
    } catch (e) {
      print('Error deleting restored file: $e');
      return false;
    }
  }

  Future<void> clearRestoredFiles() async {
    try {
      final restoredDir = await _getRestoredFilesDirectory();
      
      // Delete all files in restored folder
      await for (final entity in restoredDir.list()) {
        if (entity is File && !entity.path.endsWith(_restoredMetadataFileName)) {
          await entity.delete();
        }
      }
      
      // Clear metadata
      await _saveRestoredMetadata({});
    } catch (e) {
      print('Error clearing restored files: $e');
    }
  }

  Future<int> getRestoredFilesSize() async {
    try {
      final items = await getRestoredFiles();
      return items.fold<int>(0, (sum, item) => sum + item.size);
    } catch (e) {
      print('Error calculating restored files size: $e');
      return 0;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class RecycleBinItem {
  final String id;
  final String originalPath;
  final String originalName;
  final DateTime deletedAt;
  final int size;
  final String currentPath;
  
  RecycleBinItem({
    required this.id,
    required this.originalPath,
    required this.originalName,
    required this.deletedAt,
    required this.size,
    required this.currentPath,
  });
}

class RestoredFileItem {
  final String id;
  final String originalPath;
  final String originalName;
  final DateTime restoredAt;
  final DateTime deletedAt;
  final int size;
  final String currentPath;
  
  RestoredFileItem({
    required this.id,
    required this.originalPath,
    required this.originalName,
    required this.restoredAt,
    required this.deletedAt,
    required this.size,
    required this.currentPath,
  });
}

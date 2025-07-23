import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:path/path.dart' as pathlib;
import '../blocs/duplicate_finder_bloc.dart';
import '../blocs/duplicate_finder_state.dart';
import '../services/file_service.dart';

class ScanSummary extends StatelessWidget {
  final FileService _fileService = FileService();

  ScanSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuplicateFinderBloc, DuplicateFinderState>(
      builder: (context, state) {
        if (state is DuplicateFinderCompleted) {
          final totalDuplicates = state.duplicates.length;
          final totalFiles = state.duplicates.fold<int>(
            0, (sum, duplicate) => sum + duplicate.count,
          );
          final totalSize = state.duplicates.fold<int>(
            0, (sum, duplicate) => sum + (duplicate.size * duplicate.count),
          );
          final wastedSpace = state.duplicates.fold<int>(
            0, (sum, duplicate) => sum + (duplicate.size * (duplicate.count - 1)),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Duplicate Groups',
                      value: totalDuplicates.toString(),
                      icon: Icons.content_copy,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Files',
                      value: totalFiles.toString(),
                      icon: Icons.description,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Size',
                      value: _fileService.formatFileSize(totalSize),
                      icon: Icons.storage,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Wasted Space',
                      value: _fileService.formatFileSize(wastedSpace),
                      icon: Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              if (state.duplicates.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Recent Files',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.duplicates.take(5).length,
                    itemBuilder: (context, index) {
                      final duplicate = state.duplicates[index];
                      final firstFilePath = duplicate.paths.first;
                      final fileName = pathlib.basename(firstFilePath);
                      final folderPath = pathlib.dirname(firstFilePath);

                      return Container(
                        width: 140,
                        margin: EdgeInsets.only(right: 8),
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // File icon and name (clickable to open file)
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _openFile(firstFilePath, context),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _getFileIcon(fileName),
                                            size: 32,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            fileName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                // Folder icon (clickable to open folder)
                                InkWell(
                                  onTap: () => _openFolder(folderPath, context),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.folder_open,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Open Folder',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'All Duplicate Files',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Container(
                  height: 300,
                  child: ListView.builder(
                    itemCount: state.duplicates.length,
                    itemBuilder: (context, index) {
                      final duplicate = state.duplicates[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getFileIcon(pathlib.basename(duplicate.paths.first)),
                              color: Colors.red,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            pathlib.basename(duplicate.paths.first),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${duplicate.count} duplicates • ${_fileService.formatFileSize(duplicate.size)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete_except_oldest') {
                            await _deleteGroupKeepOldest(duplicate, context);
                          } else if (value == 'delete_except_newest') {
                            await _deleteGroupKeepNewest(duplicate, context);
                          } else if (value == 'delete_except_first') {
                            await _deleteAllExceptFirst(duplicate, context);
                          } else if (value == 'delete_all') {
                            await _deleteAllFiles(duplicate, context);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'delete_except_oldest',
                            child: Row(
                              children: [
                                Icon(Icons.history, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Keep Oldest, Delete Others'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete_except_newest',
                            child: Row(
                              children: [
                                Icon(Icons.new_releases, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Keep Newest, Delete Others'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete_except_first',
                            child: Row(
                              children: [
                                Icon(Icons.auto_delete, size: 18, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Keep First, Delete Others'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete_all',
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete All'),
                              ],
                            ),
                          ),
                        ],
                      ),
                          children: duplicate.paths.map((filePath) {
                            final fileName = pathlib.basename(filePath);
                            final folderPath = pathlib.dirname(filePath);

                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                              leading: Icon(Icons.insert_drive_file, size: 20),
                              title: Text(
                                fileName,
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                folderPath,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.folder_open, color: Colors.orange),
                                onPressed: () => _openFolder(folderPath, context),
                                tooltip: 'Open folder',
                              ),
                              onTap: () => _openFile(filePath, context),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Future<void> _deleteGroupKeepOldest(DuplicateFile duplicate, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Keep Oldest File'),
        content: Text('Keep the oldest file and delete ${duplicate.count - 1} others? This action moves duplicates to recycle bin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: Text('Keep Oldest'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<DuplicateFinderBloc>().add(DeleteDuplicateGroup(duplicate, keepOldest: true));
      _showSnackBar(context, '${duplicate.count - 1} duplicate files moved to recycle bin, oldest file kept');
    }
  }

  Future<void> _deleteGroupKeepNewest(DuplicateFile duplicate, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Keep Newest File'),
        content: Text('Keep the newest file and delete ${duplicate.count - 1} others? This action moves duplicates to recycle bin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: Text('Keep Newest'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<DuplicateFinderBloc>().add(DeleteDuplicateGroup(duplicate, keepOldest: false));
      _showSnackBar(context, '${duplicate.count - 1} duplicate files moved to recycle bin, newest file kept');
    }
  }

  Future<void> _deleteAllFiles(DuplicateFile duplicate, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Files'),
        content: Text('Are you sure you want to delete all ${duplicate.count} files? This action moves them to recycle bin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (String filePath in duplicate.paths) {
        context.read<DuplicateFinderBloc>().add(DeleteFile(filePath));
      }

      _showSnackBar(context, '${duplicate.count} files moved to recycle bin');
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = pathlib.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return Icons.image;
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.flv':
      case '.webm':
        return Icons.video_file;
      case '.mp3':
      case '.wav':
      case '.flac':
      case '.aac':
      case '.ogg':
        return Icons.audio_file;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
        return Icons.text_snippet;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive;
      case '.apk':
        return Icons.android;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _openFile(String filePath, BuildContext context) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        _showSnackBar(context, 'Could not open file: ${result.message}');
      }
    } catch (e) {
      _showSnackBar(context, 'Cannot open file: $e');
    }
  }

  Future<void> _openFolder(String folderPath, BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        // For Android, use android_intent_plus to open specific folder
        try {
          // First check if the folder exists
          final directory = Directory(folderPath);
          if (await directory.exists()) {
            // Try to open with file manager intent
            final result = await OpenFilex.open(folderPath);
            if (result.type != ResultType.done) {
              // Fallback: show folder path in snackbar
              _showSnackBar(context, 'Folder: $folderPath');
            }
          } else {
            _showSnackBar(context, 'Folder does not exist: $folderPath');
          }
        } catch (e) {
          _showSnackBar(context, 'Folder: $folderPath');
        }
      } else if (Platform.isIOS) {
        // iOS doesn't allow direct folder access, show message
        _showSnackBar(context, 'Folder access not available on iOS');
      } else {
        // For desktop platforms
        final directory = Directory(folderPath);
        if (await directory.exists()) {
          final result = await OpenFilex.open(folderPath);
          if (result.type != ResultType.done) {
            _showSnackBar(context, 'Could not open folder');
          }
        } else {
          _showSnackBar(context, 'Folder does not exist');
        }
      }
    } catch (e) {
      _showSnackBar(context, 'Error opening folder: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
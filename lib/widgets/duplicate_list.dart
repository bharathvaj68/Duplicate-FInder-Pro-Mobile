import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../blocs/duplicate_finder_bloc.dart';
import '../blocs/duplicate_finder_event.dart';
import '../blocs/duplicate_finder_state.dart';
import '../models/duplicate_file.dart';
import '../services/file_service.dart';

class DuplicateList extends StatelessWidget {
  final FileService _fileService = FileService();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuplicateFinderBloc, DuplicateFinderState>(
      builder: (context, state) {
        if (state is DuplicateFinderCompleted) {
          return ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: state.duplicates.length,
            itemBuilder: (context, index) {
              final duplicate = state.duplicates[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(
                    '${duplicate.count} identical files',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Size: ${_fileService.formatFileSize(duplicate.size)} each',
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Text(
                      '${duplicate.count}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  children: duplicate.paths.map((filePath) {
                    return ListTile(
                      leading: Icon(
                        _getFileIcon(filePath),
                        color: Colors.grey[600],
                      ),
                      title: Text(
                        path.basename(filePath),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        filePath,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'open':
                              try {
                                await OpenFilex.open(filePath);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open file: $e'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              break;
                            case 'delete':
                              _showDeleteConfirmation(context, filePath);
                              break;
                            case 'delete_all':
                              _deleteAllDuplicates(duplicate, context);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, size: 18),
                                SizedBox(width: 8),
                                Text('Open'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete_all',
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete All', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

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
      case '.mkv':
      case '.wmv':
        return Icons.video_file;
      case '.mp3':
      case '.wav':
      case '.flac':
      case '.aac':
        return Icons.audio_file;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showDeleteConfirmation(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete File'),
          content: Text(
            'Are you sure you want to delete this file?\n\n${path.basename(filePath)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<DuplicateFinderBloc>().add(DeleteFile(filePath));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllDuplicates(DuplicateFile duplicate, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Duplicate Files'),
        content: Text('This will keep the oldest file and delete ${duplicate.count - 1} duplicate copies. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete Duplicates'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Sort files by modification time to keep the oldest
      List<File> files = duplicate.paths.map((path) => File(path)).toList();
      List<MapEntry<File, DateTime>> filesWithDates = [];

      for (File file in files) {
        try {
          final stat = await file.stat();
          filesWithDates.add(MapEntry(file, stat.modified));
        } catch (e) {
          // If we can't get the date, use current time (will be deleted)
          filesWithDates.add(MapEntry(file, DateTime.now()));
        }
      }

      // Sort by modification date (oldest first)
      filesWithDates.sort((a, b) => a.value.compareTo(b.value));

      // Keep the oldest file, delete the rest
      final oldestFile = filesWithDates.first.key;
      final filesToDelete = filesWithDates.skip(1).map((e) => e.key.path).toList();

      int deletedCount = 0;
      for (String filePath in filesToDelete) {
        final success = await _fileService.deleteFile(filePath);
        if (success) {
          deletedCount++;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kept oldest file, deleted $deletedCount duplicate${deletedCount != 1 ? 's' : ''}')),
      );

      // Update the duplicate list
      for (String filePath in filesToDelete) {
        context.read<DuplicateFinderBloc>().add(DeleteFile(filePath));
      }
    }
  }
}
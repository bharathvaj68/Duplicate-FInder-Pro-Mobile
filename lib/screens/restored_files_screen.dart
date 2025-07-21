
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../services/recycle_bin_service.dart';

class RestoredFilesScreen extends StatefulWidget {
  @override
  _RestoredFilesScreenState createState() => _RestoredFilesScreenState();
}

class _RestoredFilesScreenState extends State<RestoredFilesScreen> {
  final RecycleBinService _recycleBinService = RecycleBinService();
  List<RestoredFileItem> _restoredFiles = [];
  bool _isLoading = true;
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _loadRestoredFiles();
  }

  Future<void> _loadRestoredFiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await _recycleBinService.getRestoredFiles();
      final size = await _recycleBinService.getRestoredFilesSize();
      
      setState(() {
        _restoredFiles = files;
        _totalSize = size;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading restored files: $e')),
      );
    }
  }

  Future<void> _openFile(RestoredFileItem file) async {
    try {
      await OpenFilex.open(file.currentPath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open file: $e')),
      );
    }
  }

  Future<void> _moveToOriginalLocation(RestoredFileItem file) async {
    try {
      final success = await _recycleBinService.moveToOriginalLocation(file.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${file.originalName} moved to original location')),
        );
        _loadRestoredFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to move ${file.originalName}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving file: $e')),
      );
    }
  }

  Future<void> _deleteRestoredFile(RestoredFileItem file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete File'),
        content: Text('Are you sure you want to permanently delete "${file.originalName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _recycleBinService.deleteRestoredFile(file.id);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.originalName} deleted permanently')),
          );
          _loadRestoredFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete ${file.originalName}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  Future<void> _clearAllRestoredFiles() async {
    if (_restoredFiles.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Restored Files'),
        content: Text('Are you sure you want to permanently delete all ${_restoredFiles.length} restored files? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _recycleBinService.clearRestoredFiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All restored files cleared')),
        );
        _loadRestoredFiles();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing files: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restored Files'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRestoredFiles,
            tooltip: 'Refresh',
          ),
          if (_restoredFiles.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearAllRestoredFiles,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Card(
                  margin: EdgeInsets.all(16),
                  elevation: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.folder_special,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Restored Files',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${_restoredFiles.length} files • ${_recycleBinService.formatFileSize(_totalSize)}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Files that have been restored from recycle bin',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Files List
                Expanded(
                  child: _restoredFiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_special_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Restored Files',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Restored files will appear here',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _restoredFiles.length,
                          itemBuilder: (context, index) {
                            final file = _restoredFiles[index];
                            final restoredDate = DateFormat('MMM dd, yyyy HH:mm').format(file.restoredAt);
                            final deletedDate = DateFormat('MMM dd, yyyy HH:mm').format(file.deletedAt);
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              elevation: 2,
                              child: InkWell(
                                onTap: () => _openFile(file),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.insert_drive_file,
                                          color: Theme.of(context).colorScheme.secondary,
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.originalName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Original: ${file.originalPath}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Restored: $restoredDate',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.data_usage, size: 12, color: Colors.grey[500]),
                                                SizedBox(width: 4),
                                                Text(
                                                  _recycleBinService.formatFileSize(file.size),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton(
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'open',
                                            child: Row(
                                              children: [
                                                Icon(Icons.open_in_new, size: 20),
                                                SizedBox(width: 8),
                                                Text('Open'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'move',
                                            child: Row(
                                              children: [
                                                Icon(Icons.drive_file_move, size: 20, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Move to Original Location', style: TextStyle(color: Colors.blue)),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_forever, size: 20, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete Forever', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'open') {
                                            _openFile(file);
                                          } else if (value == 'move') {
                                            _moveToOriginalLocation(file);
                                          } else if (value == 'delete') {
                                            _deleteRestoredFile(file);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

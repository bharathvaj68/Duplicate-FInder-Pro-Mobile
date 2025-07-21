
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/recycle_bin_service.dart';

class RecycleBinScreen extends StatefulWidget {
  @override
  _RecycleBinScreenState createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final RecycleBinService _recycleBinService = RecycleBinService();
  List<RecycleBinItem> _recycleBinItems = [];
  bool _isLoading = true;
  int _totalSize = 0;

  @override
  void initState() {
    super.initState();
    _loadRecycleBinItems();
  }

  Future<void> _loadRecycleBinItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _recycleBinService.getRecycleBinItems();
      final size = await _recycleBinService.getRecycleBinSize();
      
      setState(() {
        _recycleBinItems = items;
        _totalSize = size;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recycle bin: $e')),
      );
    }
  }

  Future<void> _restoreFile(RecycleBinItem item) async {
    try {
      final success = await _recycleBinService.restoreFromRecycleBin(item.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.originalName} restored successfully')),
        );
        _loadRecycleBinItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore ${item.originalName}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring file: $e')),
      );
    }
  }

  Future<void> _permanentlyDeleteFile(RecycleBinItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete "${item.originalName}"? This action cannot be undone.'),
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
        final success = await _recycleBinService.permanentlyDelete(item.id);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.originalName} permanently deleted')),
          );
          _loadRecycleBinItems();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete ${item.originalName}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  Future<void> _emptyRecycleBin() async {
    if (_recycleBinItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Empty Recycle Bin'),
        content: Text('Are you sure you want to permanently delete all ${_recycleBinItems.length} items? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Empty'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _recycleBinService.emptyRecycleBin();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recycle bin emptied')),
        );
        _loadRecycleBinItems();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error emptying recycle bin: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recycle Bin'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRecycleBinItems,
            tooltip: 'Refresh',
          ),
          if (_recycleBinItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_forever),
              onPressed: _emptyRecycleBin,
              tooltip: 'Empty Recycle Bin',
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
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 40, color: Colors.grey[600]),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_recycleBinItems.length} items',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                _recycleBinService.formatFileSize(_totalSize),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Items List
                Expanded(
                  child: _recycleBinItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Recycle Bin is Empty',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Deleted files will appear here',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _recycleBinItems.length,
                          itemBuilder: (context, index) {
                            final item = _recycleBinItems[index];
                            final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(item.deletedAt);
                            
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.insert_drive_file, color: Colors.grey[600]),
                                title: Text(
                                  item.originalName,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Original: ${item.originalPath}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Deleted: $formattedDate',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      _recycleBinService.formatFileSize(item.size),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'restore',
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore, size: 20),
                                          SizedBox(width: 8),
                                          Text('Restore'),
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
                                    if (value == 'restore') {
                                      _restoreFile(item);
                                    } else if (value == 'delete') {
                                      _permanentlyDeleteFile(item);
                                    }
                                  },
                                ),
                                isThreeLine: true,
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

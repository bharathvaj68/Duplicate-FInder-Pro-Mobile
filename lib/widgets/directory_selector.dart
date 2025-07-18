import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../blocs/duplicate_finder_bloc.dart';
import '../blocs/duplicate_finder_event.dart';
import '../blocs/duplicate_finder_state.dart';

class DirectorySelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DuplicateFinderBloc, DuplicateFinderState>(
      builder: (context, state) {
        List<String> availableDirectories = [];
        String? selectedDirectory;
        bool isScanning = false;

        if (state is DuplicateFinderDirectoriesLoaded) {
          availableDirectories = state.directories;
          selectedDirectory = state.selectedDirectory;
        } else if (state is DuplicateFinderScanning) {
          availableDirectories = state.availableDirectories;
          selectedDirectory = state.selectedDirectory;
          isScanning = true;
        } else if (state is DuplicateFinderCompleted) {
          availableDirectories = state.availableDirectories;
          selectedDirectory = state.selectedDirectory;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (availableDirectories.isNotEmpty) ...[
              Text(
                'Quick Select:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableDirectories.map((directory) {
                  bool isSelected = selectedDirectory == directory;
                  return FilterChip(
                    label: Text(
                      _getDirectoryDisplayName(directory),
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: isScanning ? null : (selected) {
                      if (selected) {
                        context.read<DuplicateFinderBloc>().add(
                          SelectDirectory(directory),
                        );
                      }
                    },
                    backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
            ],
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isScanning ? null : () async {
                      try {
                        String? selectedPath;
                        if (Platform.isIOS) {
                          // On iOS, use file picker to select files instead of directories
                          // since iOS doesn't allow direct directory access
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please select from available directories above'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        } else {
                          selectedPath = await FilePicker.platform.getDirectoryPath();
                        }
                        if (selectedPath != null) {
                          context.read<DuplicateFinderBloc>().add(
                            SelectDirectory(selectedPath),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error selecting directory: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.folder_open),
                    label: Text(Platform.isIOS ? 'Use Available Directories' : 'Browse for Directory'),
                  ),
                ),
              ],
            ),
            
            if (selectedDirectory != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedDirectory,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isScanning ? null : () {
                  context.read<DuplicateFinderBloc>().add(
                    StartScan(selectedDirectory),
                  );
                },
                icon: isScanning 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.search),
                label: Text(isScanning ? 'Scanning...' : 'Start Scan'),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getDirectoryDisplayName(String path) {
    if (path.contains('/storage/emulated/0')) {
      var relativePath = path.replaceFirst('/storage/emulated/0', '');
      if (relativePath.isEmpty) return 'Internal Storage';
      if (relativePath.startsWith('/')) relativePath = relativePath.substring(1);
      return relativePath.isEmpty ? 'Internal Storage' : relativePath;
    }
    
    var parts = path.split('/');
    if (parts.length > 2) {
      return '.../${parts.sublist(parts.length - 2).join('/')}';
    }
    return parts.last.isEmpty ? path : parts.last;
  }
}
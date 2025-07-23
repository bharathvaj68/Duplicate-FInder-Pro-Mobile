import 'package:flutter_bloc/flutter_bloc.dart';
import 'duplicate_finder_event.dart';
import 'duplicate_finder_state.dart';
import '../services/file_service.dart';
import '../services/database_service.dart';
import '../models/duplicate_file.dart';

class DuplicateFinderBloc extends Bloc<DuplicateFinderEvent, DuplicateFinderState> {
  final FileService fileService;
  final DatabaseService databaseService;

  DuplicateFinderBloc({
    required this.fileService,
    required this.databaseService,
  }) : super(DuplicateFinderInitial()) {
    on<LoadAvailableDirectories>(_onLoadAvailableDirectories);
    on<SelectDirectory>(_onSelectDirectory);
    on<StartScan>(_onStartScan);
    on<DeleteFile>(_onDeleteFile);
    on<DeleteDuplicateGroup>(_onDeleteDuplicateGroup);
    on<UpdateScanProgress>(_onUpdateScanProgress);
  }

  Future<void> _onLoadAvailableDirectories(
    LoadAvailableDirectories event,
    Emitter<DuplicateFinderState> emit,
  ) async {
    try {
      emit(DuplicateFinderInitial());
      
      final directories = await fileService.getAvailableDirectories();
      
      if (directories.isEmpty) {
        emit(DuplicateFinderError('No accessible directories found. Please check storage permissions.'));
      } else {
        emit(DuplicateFinderDirectoriesLoaded(directories));
      }
    } catch (e) {
      emit(DuplicateFinderError('Failed to load directories: ${e.toString()}'));
    }
  }

  Future<void> _onSelectDirectory(
    SelectDirectory event,
    Emitter<DuplicateFinderState> emit,
  ) async {
    try {
      List<String> availableDirectories = [];
      
      if (state is DuplicateFinderDirectoriesLoaded) {
        availableDirectories = (state as DuplicateFinderDirectoriesLoaded).directories;
      } else if (state is DuplicateFinderCompleted) {
        availableDirectories = (state as DuplicateFinderCompleted).availableDirectories;
      } else {
        // Load directories if not already loaded
        availableDirectories = await fileService.getAvailableDirectories();
      }
      
      emit(DuplicateFinderDirectoriesLoaded(
        availableDirectories,
        selectedDirectory: event.directoryPath,
      ));
    } catch (e) {
      emit(DuplicateFinderError('Failed to select directory: ${e.toString()}'));
    }
  }

  Future<void> _onStartScan(
    StartScan event,
    Emitter<DuplicateFinderState> emit,
  ) async {
    try {
      List<String> availableDirectories = [];
      
      if (state is DuplicateFinderDirectoriesLoaded) {
        availableDirectories = (state as DuplicateFinderDirectoriesLoaded).directories;
      } else {
        availableDirectories = await fileService.getAvailableDirectories();
      }

      emit(DuplicateFinderScanning(
        availableDirectories: availableDirectories,
        selectedDirectory: event.directoryPath,
        progress: 'Starting scan...',
        fileCount: 0,
      ));

      final duplicates = await fileService.scanForDuplicates(
        event.directoryPath,
        onProgress: (progress) {
          add(UpdateScanProgress(progress, null));
        },
        onFileCount: (count) {
          add(UpdateScanProgress(null, count));
        },
        onDuplicatesFound: (duplicateCount) {
          add(UpdateScanProgress('Found $duplicateCount duplicate groups...', null));
        },
      );

      // Save scan results to database
      await databaseService.saveScanResult(event.directoryPath, duplicates);

      emit(DuplicateFinderCompleted(
        availableDirectories: availableDirectories,
        selectedDirectory: event.directoryPath,
        duplicates: duplicates,
      ));
    } catch (e) {
      List<String> availableDirectories = [];
      try {
        availableDirectories = await fileService.getAvailableDirectories();
      } catch (_) {}
      
      emit(DuplicateFinderError('Scan failed: ${e.toString()}'));
      
      // Return to directory selection state
      if (availableDirectories.isNotEmpty) {
        emit(DuplicateFinderDirectoriesLoaded(
          availableDirectories,
          selectedDirectory: event.directoryPath,
        ));
      }
    }
  }

  Future<void> _onDeleteFile(
    DeleteFile event,
    Emitter<DuplicateFinderState> emit,
  ) async {
    if (state is DuplicateFinderCompleted) {
      final currentState = state as DuplicateFinderCompleted;
      
      try {
        final success = await fileService.deleteFile(event.filePath);
        
        if (success) {
          // Update the duplicates list
          final updatedDuplicates = currentState.duplicates.map((duplicate) {
            if (duplicate.paths.contains(event.filePath)) {
              final updatedPaths = duplicate.paths.where((path) => path != event.filePath).toList();
              
              if (updatedPaths.length > 1) {
                return DuplicateFile(
                  paths: updatedPaths,
                  size: duplicate.size,
                  hash: duplicate.hash,
                  count: updatedPaths.length,
                );
              } else {
                return null; // Remove this duplicate group
              }
            }
            return duplicate;
          }).where((duplicate) => duplicate != null).cast<DuplicateFile>().toList();

          emit(DuplicateFinderCompleted(
            availableDirectories: currentState.availableDirectories,
            selectedDirectory: currentState.selectedDirectory,
            duplicates: updatedDuplicates,
          ));
        }
      } catch (e) {
        // Handle error but don't change state
        print('Error deleting file: $e');
      }
    }
  }

  Future<void> _onDeleteDuplicateGroup(
    DeleteDuplicateGroup event,
    Emitter<DuplicateFinderState> emit,
  ) async {
    if (state is DuplicateFinderCompleted) {
      final currentState = state as DuplicateFinderCompleted;
      
      try {
        final success = await fileService.deleteDuplicateGroup(
          event.duplicateGroup,
          keepOldest: event.keepOldest,
        );
        
        if (success) {
          // Remove the deleted group from the duplicates list
          final updatedDuplicates = currentState.duplicates
              .where((duplicate) => duplicate.hash != event.duplicateGroup.hash)
              .toList();

          emit(DuplicateFinderCompleted(
            availableDirectories: currentState.availableDirectories,
            selectedDirectory: currentState.selectedDirectory,
            duplicates: updatedDuplicates,
          ));
        }
      } catch (e) {
        print('Error deleting duplicate group: $e');
      }
    }
  }

  Future<void> _onUpdateScanProgress(
    UpdateScanProgress event,
    Emitter<DuplicateFinderState> emit,
  ) async {
    if (state is DuplicateFinderScanning) {
      final currentState = state as DuplicateFinderScanning;
      
      emit(DuplicateFinderScanning(
        availableDirectories: currentState.availableDirectories,
        selectedDirectory: currentState.selectedDirectory,
        progress: event.progress ?? currentState.progress,
        fileCount: event.fileCount ?? currentState.fileCount,
      ));
    }
  }
}
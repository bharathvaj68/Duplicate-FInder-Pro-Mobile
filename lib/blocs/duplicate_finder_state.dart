import '../models/duplicate_file.dart';

abstract class DuplicateFinderState {}

class DuplicateFinderInitial extends DuplicateFinderState {}

class DuplicateFinderDirectoriesLoaded extends DuplicateFinderState {
  final List<String> directories;
  final String? selectedDirectory;
  
  DuplicateFinderDirectoriesLoaded(
    this.directories, {
    this.selectedDirectory,
  });
}

class DuplicateFinderScanning extends DuplicateFinderState {
  final List<String> availableDirectories;
  final String selectedDirectory;
  final String progress;
  final int fileCount;
  
  DuplicateFinderScanning({
    required this.availableDirectories,
    required this.selectedDirectory,
    required this.progress,
    required this.fileCount,
  });
}

class DuplicateFinderCompleted extends DuplicateFinderState {
  final List<String> availableDirectories;
  final String selectedDirectory;
  final List<DuplicateFile> duplicates;
  
  DuplicateFinderCompleted({
    required this.availableDirectories,
    required this.selectedDirectory,
    required this.duplicates,
  });
}

class DuplicateFinderError extends DuplicateFinderState {
  final String message;
  
  DuplicateFinderError(this.message);
}
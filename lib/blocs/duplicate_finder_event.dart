abstract class DuplicateFinderEvent {}

class LoadAvailableDirectories extends DuplicateFinderEvent {}

class SelectDirectory extends DuplicateFinderEvent {
  final String directoryPath;
  
  SelectDirectory(this.directoryPath);
}

class StartScan extends DuplicateFinderEvent {
  final String directoryPath;
  
  StartScan(this.directoryPath);
}

class DeleteFile extends DuplicateFinderEvent {
  final String filePath;
  
  DeleteFile(this.filePath);
}

class UpdateScanProgress extends DuplicateFinderEvent {
  final String? progress;
  final int? fileCount;
  
  UpdateScanProgress(this.progress, this.fileCount);
}
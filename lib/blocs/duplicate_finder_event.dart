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

  const UpdateScanProgress(this.progress, this.fileCount);

  @override
  List<Object?> get props => [progress, fileCount];
}

class DeleteDuplicateGroup extends DuplicateFinderEvent {
  final DuplicateFile duplicateGroup;
  final bool keepOldest;

  const DeleteDuplicateGroup(this.duplicateGroup, {this.keepOldest = true});

  @override
  List<Object?> get props => [duplicateGroup, keepOldest];
}
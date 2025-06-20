class DuplicateFile {
  final List<String> paths;
  final int size;
  final String hash;
  final int count;

  DuplicateFile({
    required this.paths,
    required this.size,
    required this.hash,
    required this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'paths': paths.join('|'),
      'size': size,
      'hash': hash,
      'count': count,
    };
  }

  factory DuplicateFile.fromMap(Map<String, dynamic> map) {
    return DuplicateFile(
      paths: map['paths'].toString().split('|'),
      size: map['size'] ?? 0,
      hash: map['hash'] ?? '',
      count: map['count'] ?? 0,
    );
  }
}
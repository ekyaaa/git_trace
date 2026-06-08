class RepositoryModel {
  final String name;
  final String path;
  final DateTime? lastCommitDate;
  final int totalCommits;

  const RepositoryModel({
    required this.name,
    required this.path,
    this.lastCommitDate,
    this.totalCommits = 0,
  });

  RepositoryModel copyWith({
    String? name,
    String? path,
    DateTime? lastCommitDate,
    int? totalCommits,
  }) {
    return RepositoryModel(
      name: name ?? this.name,
      path: path ?? this.path,
      lastCommitDate: lastCommitDate ?? this.lastCommitDate,
      totalCommits: totalCommits ?? this.totalCommits,
    );
  }

  @override
  String toString() =>
      'RepositoryModel(name: $name, path: $path, commits: $totalCommits)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositoryModel &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}

class CommitModel {
  final String hash;
  final String shortHash;
  final String authorName;
  final String authorEmail;
  final DateTime timestamp;
  final String subject;
  final String body;
  final String repoName;
  final String repoPath;

  const CommitModel({
    required this.hash,
    required this.shortHash,
    required this.authorName,
    required this.authorEmail,
    required this.timestamp,
    required this.subject,
    this.body = '',
    required this.repoName,
    required this.repoPath,
  });

  /// Returns the time in HH:MM format.
  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Returns the date-only portion of the timestamp.
  DateTime get dateOnly => DateTime(
        timestamp.year,
        timestamp.month,
        timestamp.day,
      );

  @override
  String toString() =>
      'CommitModel(hash: $shortHash, repo: $repoName, subject: $subject)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitModel &&
          runtimeType == other.runtimeType &&
          hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}

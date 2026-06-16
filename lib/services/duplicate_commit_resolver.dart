import '../models/commit_model.dart';

class DuplicateCommitResolver {
  /// Finds groups of commits in the same repository on the same day.
  /// Returns a map of date -> list of duplicate groups.
  /// Each duplicate group is a list of commits sharing the same repoPath.
  static Map<DateTime, List<List<CommitModel>>> findDuplicateGroups(
    List<CommitModel> commits,
    int month,
    int year,
  ) {
    final commitsByDate = <DateTime, List<CommitModel>>{};
    for (final commit in commits) {
      final dateKey = commit.dateOnly;
      commitsByDate.putIfAbsent(dateKey, () => []).add(commit);
    }

    final result = <DateTime, List<List<CommitModel>>>{};

    for (final entry in commitsByDate.entries) {
      final date = entry.key;
      final dateCommits = entry.value;

      if (dateCommits.length < 2) continue;

      // Group by repoPath
      final groups = <String, List<CommitModel>>{};
      for (final c in dateCommits) {
        groups.putIfAbsent(c.repoPath, () => []).add(c);
      }

      // Filter only groups with more than one commit (duplicates)
      final duplicates = <List<CommitModel>>[];
      for (final group in groups.values) {
        if (group.length > 1) {
          duplicates.add(group);
        }
      }

      if (duplicates.isNotEmpty) {
        result[date] = duplicates;
      }
    }

    return result;
  }

  /// Counts total duplicate commits in a month (commits that are part of a
  /// duplicate group, excluding the first occurrence per group).
  static int countExtraDuplicates(
    List<CommitModel> commits,
    int month,
    int year,
  ) {
    final groups = findDuplicateGroups(commits, month, year);
    int count = 0;
    for (final dayGroups in groups.values) {
      for (final group in dayGroups) {
        count += group.length - 1;
      }
    }
    return count;
  }

  /// Checks whether any duplicates exist in the given month.
  static bool hasDuplicates(
    List<CommitModel> commits,
    int month,
    int year,
  ) {
    return findDuplicateGroups(commits, month, year).isNotEmpty;
  }

  /// Builds the "kegiatan" string with duplicate commits merged.
  /// Commits in the same repository on the same day are combined.
  /// Each group is formatted as:
  ///   - [repoName] subject1, subject2, ...
  static String buildMergedKegiatan(List<CommitModel> dateCommits) {
    if (dateCommits.isEmpty) return '';

    // Group by repoPath
    final groups = <String, List<CommitModel>>{};
    for (final c in dateCommits) {
      groups.putIfAbsent(c.repoPath, () => []).add(c);
    }

    final lines = <String>[];
    for (final group in groups.values) {
      final firstCommit = group.first;
      // Get unique subjects to avoid repeating identical commit messages
      final uniqueSubjects = group.map((c) => c.subject).toSet().toList();
      lines.add('- [${firstCommit.repoName}] ${uniqueSubjects.join(', ')}');
    }

    return lines.join('\n');
  }

  /// Builds the "kegiatan" string with commits kept separate (original behavior).
  /// Each commit gets its own line formatted as:
  ///   - [repoName] subject
  static String buildSeparateKegiatan(List<CommitModel> dateCommits) {
    return dateCommits
        .map((c) => '- [${c.repoName}] ${c.subject}')
        .join('\n');
  }

  /// Returns true if a specific commit is part of a duplicate group
  /// on its day. Useful for UI indicators.
  static bool isDuplicate(
    CommitModel commit,
    List<CommitModel> allDayCommits,
  ) {
    if (allDayCommits.length < 2) return false;
    return allDayCommits.any(
      (other) =>
          other != commit &&
          other.hash != commit.hash &&
          other.repoPath == commit.repoPath,
    );
  }
}

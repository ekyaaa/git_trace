import '../models/commit_model.dart';

class DuplicateCommitResolver {
  /// Finds groups of commits with the same subject on the same day.
  /// Returns a map of date -> list of duplicate groups.
  /// Each duplicate group is a list of commits sharing the same subject.
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

      // Group by subject
      final subjectGroups = <String, List<CommitModel>>{};
      for (final c in dateCommits) {
        subjectGroups.putIfAbsent(c.subject, () => []).add(c);
      }

      // Filter only groups with more than one commit (duplicates)
      final duplicates = <List<CommitModel>>[];
      for (final group in subjectGroups.values) {
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
  /// Commits with the same subject on the same day are combined into one line:
  ///   [repo1, repo2] subject
  /// Unique commits remain one line:
  ///   [repo] subject
  static String buildMergedKegiatan(List<CommitModel> dateCommits) {
    if (dateCommits.isEmpty) return '';

    // Group by subject
    final subjectGroups = <String, List<CommitModel>>{};
    for (final c in dateCommits) {
      subjectGroups.putIfAbsent(c.subject, () => []).add(c);
    }

    final lines = <String>[];
    for (final entry in subjectGroups.entries) {
      final subject = entry.key;
      final group = entry.value;

      if (group.length > 1) {
        // Merge: collect unique repo names
        final repoNames = group.map((c) => c.repoName).toSet().toList();
        if (repoNames.length == 1) {
          lines.add('[${repoNames.first}] $subject');
        } else {
          lines.add('[${repoNames.join(', ')}] $subject');
        }
      } else {
        lines.add('[${group.first.repoName}] $subject');
      }
    }

    return lines.join('\n');
  }

  /// Builds the "kegiatan" string with commits kept separate (original behavior).
  /// Each commit gets its own line:
  ///   [repo] subject
  static String buildSeparateKegiatan(List<CommitModel> dateCommits) {
    return dateCommits
        .map((c) => '[${c.repoName}] ${c.subject}')
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
          other.subject == commit.subject,
    );
  }
}

import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/commit_model.dart';

class GitLogParser {
  /// Fetches all commits from [repoPaths] for the given [month] and [year].
  /// Returns commits sorted by timestamp (earliest first).
  static Future<List<CommitModel>> getCommits({
    required List<String> repoPaths,
    required int month,
    required int year,
  }) async {
    final allCommits = <CommitModel>[];

    // Calculate date range for the month
    final afterDate = DateTime(year, month, 1);
    final beforeDate = DateTime(year, month + 1, 1);

    final afterStr = afterDate.toIso8601String();
    final beforeStr = beforeDate.toIso8601String();

    for (final repoPath in repoPaths) {
      try {
        final commits = await _getRepoCommits(
          repoPath: repoPath,
          afterStr: afterStr,
          beforeStr: beforeStr,
        );
        allCommits.addAll(commits);
      } catch (e) {
        // Skip repos that fail
      }
    }

    // Sort by timestamp (earliest first)
    allCommits.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return allCommits;
  }

  static Future<List<CommitModel>> _getRepoCommits({
    required String repoPath,
    required String afterStr,
    required String beforeStr,
  }) async {
    final repoName = p.basename(repoPath);
    final separator = '__|__';
    final format = '%H$separator%an$separator%ae$separator%ai$separator%s';

    final result = await Process.run(
      'git',
      [
        '-C',
        repoPath,
        'log',
        '--format=$format',
        '--after=$afterStr',
        '--before=$beforeStr',
        '--no-merges',
        '--all',
      ],
    );

    if (result.exitCode != 0) return [];

    final output = result.stdout.toString().trim();
    if (output.isEmpty) return [];

    final lines = output.split('\n');
    final commits = <CommitModel>[];

    for (final line in lines) {
      final parts = line.split(separator);
      if (parts.length < 5) continue;

      final hash = parts[0].trim();
      final authorName = parts[1].trim();
      final authorEmail = parts[2].trim();
      final timestampStr = parts[3].trim();
      final subject = parts[4].trim();

      // Parse the git date format: "2026-01-13 10:30:45 +0700"
      DateTime? timestamp;
      try {
        // Convert git date format to ISO 8601
        final normalized = timestampStr.replaceFirst(' ', 'T').replaceFirst(RegExp(r' ([+-])'), r'$1');
        timestamp = DateTime.tryParse(normalized);
        timestamp ??= _parseGitDate(timestampStr);
      } catch (_) {
        timestamp = _parseGitDate(timestampStr);
      }

      if (timestamp == null) continue;

      commits.add(CommitModel(
        hash: hash,
        shortHash: hash.length >= 7 ? hash.substring(0, 7) : hash,
        authorName: authorName,
        authorEmail: authorEmail,
        timestamp: timestamp,
        subject: subject,
        repoName: repoName,
        repoPath: repoPath,
      ));
    }

    return commits;
  }

  /// Fallback git date parser for format: "2026-01-13 10:30:45 +0700"
  static DateTime? _parseGitDate(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length < 2) return null;

      final datePart = parts[0];
      final timePart = parts[1];

      final dateParts = datePart.split('-');
      final timeParts = timePart.split(':');

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (_) {
      return null;
    }
  }
}

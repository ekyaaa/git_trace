import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/repository_model.dart';

class GitScanner {
  /// Recursively scans [rootPath] for Git repositories.
  /// Returns a list of [RepositoryModel] for each found repository.
  static Future<List<RepositoryModel>> scanRepositories(String rootPath) async {
    final directory = Directory(rootPath);
    if (!await directory.exists()) {
      return [];
    }

    final repos = <RepositoryModel>[];
    await _scanDirectory(directory, repos);

    // Sort by name
    repos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return repos;
  }

  static Future<void> _scanDirectory(
    Directory directory,
    List<RepositoryModel> repos,
  ) async {
    try {
      final entities = directory.listSync(followLinks: false);
      bool hasGitDir = false;

      for (final entity in entities) {
        if (entity is Directory && p.basename(entity.path) == '.git') {
          hasGitDir = true;
          break;
        }
      }

      if (hasGitDir) {
        // This directory is a git repo
        final repo = await _buildRepoModel(directory.path);
        if (repo != null) {
          repos.add(repo);
        }
        // Don't recurse into subfolders of a git repo
        return;
      }

      // Recurse into subdirectories
      for (final entity in entities) {
        if (entity is Directory) {
          final name = p.basename(entity.path);
          // Skip hidden directories and common non-project dirs
          if (name.startsWith('.') ||
              name == 'node_modules' ||
              name == 'build' ||
              name == '.dart_tool' ||
              name == '__pycache__') {
            continue;
          }
          await _scanDirectory(entity, repos);
        }
      }
    } catch (e) {
      // Permission denied or other errors — skip this directory
    }
  }

  static Future<RepositoryModel?> _buildRepoModel(String repoPath) async {
    try {
      // Verify it's a valid git repo
      final verifyResult = await Process.run(
        'git',
        ['-C', repoPath, 'rev-parse', '--git-dir'],
      );
      if (verifyResult.exitCode != 0) return null;

      // Get total commit count
      int totalCommits = 0;
      final countResult = await Process.run(
        'git',
        ['-C', repoPath, 'rev-list', '--count', 'HEAD'],
      );
      if (countResult.exitCode == 0) {
        totalCommits = int.tryParse(countResult.stdout.toString().trim()) ?? 0;
      }

      // Get last commit date
      DateTime? lastCommitDate;
      final lastCommitResult = await Process.run(
        'git',
        ['-C', repoPath, 'log', '-1', '--format=%ai'],
      );
      if (lastCommitResult.exitCode == 0) {
        final dateStr = lastCommitResult.stdout.toString().trim();
        if (dateStr.isNotEmpty) {
          lastCommitDate = DateTime.tryParse(dateStr.replaceAll(' ', 'T'));
        }
      }

      return RepositoryModel(
        name: p.basename(repoPath),
        path: repoPath,
        lastCommitDate: lastCommitDate,
        totalCommits: totalCommits,
      );
    } catch (e) {
      return null;
    }
  }
}

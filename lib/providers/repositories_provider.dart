import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/repository_model.dart';
import '../services/git_scanner.dart';
import 'folder_provider.dart';

/// Provider that scans for repositories when the folder changes.
final repositoriesProvider =
    StateNotifierProvider<RepositoriesNotifier, AsyncValue<List<RepositoryModel>>>((ref) {
  return RepositoriesNotifier(ref);
});

class RepositoriesNotifier extends StateNotifier<AsyncValue<List<RepositoryModel>>> {
  final Ref ref;

  RepositoriesNotifier(this.ref) : super(const AsyncValue.data([])) {
    // Listen to folder changes
    ref.listen<String?>(folderProvider, (previous, next) {
      if (next != null && next != previous) {
        scan(next);
      }
    });

    // Initial scan if folder is already set
    final currentFolder = ref.read(folderProvider);
    if (currentFolder != null) {
      scan(currentFolder);
    }
  }

  Future<void> scan(String rootPath) async {
    state = const AsyncValue.loading();
    try {
      final repos = await GitScanner.scanRepositories(rootPath);
      state = AsyncValue.data(repos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    final folder = ref.read(folderProvider);
    if (folder != null) {
      await scan(folder);
    }
  }
}

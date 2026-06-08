import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/work_hours_storage.dart';

/// Provider for the selected root folder path.
final folderProvider = StateNotifierProvider<FolderNotifier, String?>((ref) {
  return FolderNotifier();
});

class FolderNotifier extends StateNotifier<String?> {
  FolderNotifier() : super(null) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    state = await WorkHoursStorage.getRootFolder();
  }

  Future<void> setFolder(String path) async {
    state = path;
    await WorkHoursStorage.saveRootFolder(path);
  }

  void clear() {
    state = null;
  }
}

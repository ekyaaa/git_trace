import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import 'commits_provider.dart';

/// Provider for the set of selected repository paths.
final selectedReposProvider =
    StateNotifierProvider<SelectedReposNotifier, Set<String>>((ref) {
  return SelectedReposNotifier(ref);
});

class SelectedReposNotifier extends StateNotifier<Set<String>> {
  final Ref ref;

  SelectedReposNotifier(this.ref) : super({}) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(AppConstants.prefKeySelectedRepos);
    if (list != null) {
      state = list.toSet();
      // Auto-load commits once selections are successfully loaded
      ref.read(commitsProvider.notifier).loadCommits();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.prefKeySelectedRepos, state.toList());
  }

  void toggle(String repoPath) {
    if (state.contains(repoPath)) {
      state = {...state}..remove(repoPath);
    } else {
      state = {...state, repoPath};
    }
    _save();
  }

  void selectAll(List<String> paths) {
    state = {...paths};
    _save();
  }

  void deselectAll() {
    state = {};
    _save();
  }

  bool isSelected(String repoPath) => state.contains(repoPath);
}

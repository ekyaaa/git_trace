import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the set of selected repository paths.
final selectedReposProvider =
    StateNotifierProvider<SelectedReposNotifier, Set<String>>((ref) {
  return SelectedReposNotifier();
});

class SelectedReposNotifier extends StateNotifier<Set<String>> {
  SelectedReposNotifier() : super({});

  void toggle(String repoPath) {
    if (state.contains(repoPath)) {
      state = {...state}..remove(repoPath);
    } else {
      state = {...state, repoPath};
    }
  }

  void selectAll(List<String> paths) {
    state = {...paths};
  }

  void deselectAll() {
    state = {};
  }

  bool isSelected(String repoPath) => state.contains(repoPath);
}

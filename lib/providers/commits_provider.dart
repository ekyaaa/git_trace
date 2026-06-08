import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/commit_model.dart';
import '../services/git_log_parser.dart';
import 'selected_repos_provider.dart';
import 'calendar_provider.dart';

/// Provider that fetches commits for selected repos and current month/year.
final commitsProvider =
    StateNotifierProvider<CommitsNotifier, AsyncValue<List<CommitModel>>>((ref) {
  return CommitsNotifier(ref);
});

class CommitsNotifier extends StateNotifier<AsyncValue<List<CommitModel>>> {
  final Ref ref;

  CommitsNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> loadCommits() async {
    final selectedRepos = ref.read(selectedReposProvider);
    final calendarState = ref.read(calendarStateProvider);

    if (selectedRepos.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final commits = await GitLogParser.getCommits(
        repoPaths: selectedRepos.toList(),
        month: calendarState.month,
        year: calendarState.year,
      );
      state = AsyncValue.data(commits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

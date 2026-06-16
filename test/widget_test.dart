import 'package:flutter_test/flutter_test.dart';
import 'package:git_trace/models/commit_model.dart';
import 'package:git_trace/services/excel_exporter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:git_trace/services/draft_kegiatan_storage.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ExcelExporter should include weekdays always, and weekends only with commits', () async {
    // June 2026: 30 days, 22 weekdays, 8 weekend days
    final year = 2026;
    final month = 6;

    // Test Case 1: No commits. Expected: 22 weekday rows.
    final rowsNoCommits = await ExcelExporter.buildReportRows([], month, year);
    expect(rowsNoCommits.length, 22);

    // Test Case 2: Commits on both a weekday and a weekend.
    final commits = [
      // Weekday: Wednesday, June 3rd, 2026
      CommitModel(
        hash: 'hash1',
        shortHash: 'hash1',
        authorName: 'intern',
        authorEmail: 'intern@example.com',
        timestamp: DateTime(2026, 6, 3, 10, 0),
        subject: 'feat: weekday commit',
        repoName: 'git_trace',
        repoPath: '/path/to/repo',
      ),
      // Weekend: Saturday, June 6th, 2026
      CommitModel(
        hash: 'hash2',
        shortHash: 'hash2',
        authorName: 'intern',
        authorEmail: 'intern@example.com',
        timestamp: DateTime(2026, 6, 6, 14, 0),
        subject: 'feat: weekend commit',
        repoName: 'git_trace',
        repoPath: '/path/to/repo',
      ),
    ];

    final rowsWithCommits = await ExcelExporter.buildReportRows(commits, month, year);
    // Expected: 22 weekdays + 1 weekend (June 6th) = 23 rows.
    expect(rowsWithCommits.length, 23);

    // Verify Saturday, June 6th row exists in the results.
    final hasSaturday = rowsWithCommits.any((r) => r.dayDate.contains('Sabtu, 6 Jun'));
    expect(hasSaturday, isTrue);

    // Verify Saturday row has the commit activity description.
    final saturdayRow = rowsWithCommits.firstWhere((r) => r.dayDate.contains('Sabtu, 6 Jun'));
    expect(saturdayRow.kegiatan, contains('[git_trace] feat: weekend commit'));
  });

  test('ExcelExporter should use draft kegiatan if available', () async {
    final year = 2026;
    final month = 6;
    final dateKey = '2026-06-03';

    await DraftKegiatanStorage.setDraftKegiatan(dateKey, 'Custom Edited Kegiatan');

    final commits = [
      CommitModel(
        hash: 'hash1',
        shortHash: 'hash1',
        authorName: 'intern',
        authorEmail: 'intern@example.com',
        timestamp: DateTime(2026, 6, 3, 10, 0),
        subject: 'feat: weekday commit',
        repoName: 'git_trace',
        repoPath: '/path/to/repo',
      ),
    ];

    final rows = await ExcelExporter.buildReportRows(commits, month, year);
    final row = rows.firstWhere((r) => r.dayDate.contains('Rabu, 3 Jun'));
    expect(row.kegiatan, 'Custom Edited Kegiatan');

    // Reset it
    await DraftKegiatanStorage.removeDraftKegiatan(dateKey);
    final resetRows = await ExcelExporter.buildReportRows(commits, month, year);
    final resetRow = resetRows.firstWhere((r) => r.dayDate.contains('Rabu, 3 Jun'));
    expect(resetRow.kegiatan, contains('[git_trace] feat: weekday commit'));
  });
}

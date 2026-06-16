import 'package:shared_preferences/shared_preferences.dart';

class DraftKegiatanStorage {
  static SharedPreferences? _prefs;
  static const String _prefix = 'draft_kegiatan_';

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Gets stored draft kegiatan for a specific date (ISO format YYYY-MM-DD).
  static Future<String?> getDraftKegiatan(String dateKey) async {
    final prefs = await _instance;
    return prefs.getString('$_prefix$dateKey');
  }

  /// Saves draft kegiatan for a specific date.
  static Future<void> setDraftKegiatan(String dateKey, String kegiatan) async {
    final prefs = await _instance;
    await prefs.setString('$_prefix$dateKey', kegiatan);
  }

  /// Removes draft kegiatan for a specific date.
  static Future<void> removeDraftKegiatan(String dateKey) async {
    final prefs = await _instance;
    await prefs.remove('$_prefix$dateKey');
  }

  /// Clears all draft kegiatan for a given month.
  static Future<void> clearMonthDrafts(int year, int month) async {
    final prefs = await _instance;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey =
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      await prefs.remove('$_prefix$dateKey');
    }
  }
}

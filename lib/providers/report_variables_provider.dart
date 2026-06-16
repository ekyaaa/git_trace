import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_variable_model.dart';

final reportVariablesProvider = StateNotifierProvider<ReportVariablesNotifier, ReportVariableModel>(
  (ref) => ReportVariablesNotifier(),
);

class ReportVariablesNotifier extends StateNotifier<ReportVariableModel> {
  static const _key = 'report_variables';

  bool _isUserModified = false;
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  Timer? _saveDebounce;

  ReportVariablesNotifier() : super(ReportVariableModel()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final loaded = ReportVariableModel.fromJson(json);
        if (!_isUserModified) {
          state = loaded;
        }
        _isLoaded = true;
        print('[ReportVars] Loaded from storage: namaMahasiswa="${loaded.namaMahasiswa}", namaPembimbing="${loaded.namaPembimbing}", namaPembimbingLapangan="${loaded.namaPembimbingLapangan}"');
      } else {
        _isLoaded = true;
      }
    } catch (_) {
      _isLoaded = true;
    }
  }

  Future<void> save() async {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_key, jsonEncode(state.toJson()));
      } catch (_) {}
    });
  }

  Future<void> saveImmediate() async {
    _saveDebounce?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  void update({
    String? nama,
    String? nim,
    String? prodi,
    String? mitra,
    String? namaMahasiswa,
    String? namaPembimbing,
    String? namaPembimbingLapangan,
    String? customTemplatePath,
  }) {
    _isUserModified = true;
    state = state.copyWith(
      nama: nama,
      nim: nim,
      prodi: prodi,
      mitra: mitra,
      namaMahasiswa: namaMahasiswa,
      namaPembimbing: namaPembimbing,
      namaPembimbingLapangan: namaPembimbingLapangan,
      customTemplatePath: customTemplatePath,
    );
    print('[ReportVars] Updated: nama="${state.nama}", namaMahasiswa="${state.namaMahasiswa}", namaPembimbing="${state.namaPembimbing}", namaPembimbingLapangan="${state.namaPembimbingLapangan}"');
  }

  void setCustomTemplatePath(String? path) {
    state = state.copyWith(customTemplatePath: path);
  }

  void clearCustomTemplate() {
    state = state.copyWith(customTemplatePath: null);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    saveImmediate();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_variable_model.dart';

final reportVariablesProvider = StateNotifierProvider<ReportVariablesNotifier, ReportVariableModel>(
  (ref) => ReportVariablesNotifier(),
);

class ReportVariablesNotifier extends StateNotifier<ReportVariableModel> {
  static const _key = 'report_variables';

  ReportVariablesNotifier() : super(ReportVariableModel()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = ReportVariableModel.fromJson(json);
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  void update({
    String? nama,
    String? nim,
    String? prodi,
    String? mitra,
    String? pembimbing,
    String? pembimbingLapangan,
    String? namaMahasiswa,
    String? namaPembimbing,
    String? namaPembimbingLapangan,
    String? customTemplatePath,
  }) {
    state = state.copyWith(
      nama: nama,
      nim: nim,
      prodi: prodi,
      mitra: mitra,
      pembimbing: pembimbing,
      pembimbingLapangan: pembimbingLapangan,
      namaMahasiswa: namaMahasiswa,
      namaPembimbing: namaPembimbing,
      namaPembimbingLapangan: namaPembimbingLapangan,
      customTemplatePath: customTemplatePath,
    );
  }

  void setCustomTemplatePath(String? path) {
    state = state.copyWith(customTemplatePath: path);
  }

  void clearCustomTemplate() {
    state = state.copyWith(customTemplatePath: null);
  }
}

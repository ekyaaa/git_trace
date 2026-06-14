import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/theme_colors.dart';
import '../../models/report_variable_model.dart';
import '../../providers/report_variables_provider.dart';

class ReportVariableForm extends ConsumerStatefulWidget {
  const ReportVariableForm({super.key});

  @override
  ConsumerState<ReportVariableForm> createState() => _ReportVariableFormState();
}

class _ReportVariableFormState extends ConsumerState<ReportVariableForm> {
  late TextEditingController _namaCtrl;
  late TextEditingController _nimCtrl;
  late TextEditingController _prodiCtrl;
  late TextEditingController _mitraCtrl;
  late TextEditingController _namaMahasiswaCtrl;
  late TextEditingController _namaPembimbingCtrl;
  late TextEditingController _namaPembimbingLapanganCtrl;
  bool _expanded = false;

  void _autoSave() {
    ref.read(reportVariablesProvider.notifier).update(
      nama: _namaCtrl.text,
      nim: _nimCtrl.text,
      prodi: _prodiCtrl.text,
      mitra: _mitraCtrl.text,
      namaMahasiswa: _namaMahasiswaCtrl.text,
      namaPembimbing: _namaPembimbingCtrl.text,
      namaPembimbingLapangan: _namaPembimbingLapanganCtrl.text,
    );
    ref.read(reportVariablesProvider.notifier).save();
  }

  void _syncControllersFromProvider(ReportVariableModel vars) {
    if (_namaCtrl.text.isEmpty && vars.nama.isNotEmpty) _namaCtrl.text = vars.nama;
    if (_nimCtrl.text.isEmpty && vars.nim.isNotEmpty) _nimCtrl.text = vars.nim;
    if (_prodiCtrl.text.isEmpty && vars.prodi.isNotEmpty) _prodiCtrl.text = vars.prodi;
    if (_mitraCtrl.text.isEmpty && vars.mitra.isNotEmpty) _mitraCtrl.text = vars.mitra;
    if (_namaMahasiswaCtrl.text.isEmpty && vars.namaMahasiswa.isNotEmpty) _namaMahasiswaCtrl.text = vars.namaMahasiswa;
    if (_namaPembimbingCtrl.text.isEmpty && vars.namaPembimbing.isNotEmpty) _namaPembimbingCtrl.text = vars.namaPembimbing;
    if (_namaPembimbingLapanganCtrl.text.isEmpty && vars.namaPembimbingLapangan.isNotEmpty) _namaPembimbingLapanganCtrl.text = vars.namaPembimbingLapangan;
  }

  @override
  void initState() {
    super.initState();
    final vars = ref.read(reportVariablesProvider);
    _namaCtrl = TextEditingController(text: vars.nama);
    _nimCtrl = TextEditingController(text: vars.nim);
    _prodiCtrl = TextEditingController(text: vars.prodi);
    _mitraCtrl = TextEditingController(text: vars.mitra);
    _namaMahasiswaCtrl = TextEditingController(text: vars.namaMahasiswa);
    _namaPembimbingCtrl = TextEditingController(text: vars.namaPembimbing);
    _namaPembimbingLapanganCtrl = TextEditingController(text: vars.namaPembimbingLapangan);

    _namaCtrl.addListener(_autoSave);
    _nimCtrl.addListener(_autoSave);
    _prodiCtrl.addListener(_autoSave);
    _mitraCtrl.addListener(_autoSave);
    _namaMahasiswaCtrl.addListener(_autoSave);
    _namaPembimbingCtrl.addListener(_autoSave);
    _namaPembimbingLapanganCtrl.addListener(_autoSave);
  }

  @override
  void dispose() {
    _namaCtrl.removeListener(_autoSave);
    _nimCtrl.removeListener(_autoSave);
    _prodiCtrl.removeListener(_autoSave);
    _mitraCtrl.removeListener(_autoSave);
    _namaMahasiswaCtrl.removeListener(_autoSave);
    _namaPembimbingCtrl.removeListener(_autoSave);
    _namaPembimbingLapanganCtrl.removeListener(_autoSave);
    _namaCtrl.dispose();
    _nimCtrl.dispose();
    _prodiCtrl.dispose();
    _mitraCtrl.dispose();
    _namaMahasiswaCtrl.dispose();
    _namaPembimbingCtrl.dispose();
    _namaPembimbingLapanganCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final colors = ThemeColors.of(context);
    ref.read(reportVariablesProvider.notifier).update(
      nama: _namaCtrl.text,
      nim: _nimCtrl.text,
      prodi: _prodiCtrl.text,
      mitra: _mitraCtrl.text,
      namaMahasiswa: _namaMahasiswaCtrl.text,
      namaPembimbing: _namaPembimbingCtrl.text,
      namaPembimbingLapangan: _namaPembimbingLapanganCtrl.text,
    );
    ref.read(reportVariablesProvider.notifier).saveImmediate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data instansi berhasil disimpan.'),
        backgroundColor: colors.accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    ref.listen<ReportVariableModel>(reportVariablesProvider, (prev, next) {
      if (prev != null) {
        final wasEmpty = prev.nama.isEmpty && prev.nim.isEmpty;
        final nowHasData = next.nama.isNotEmpty || next.nim.isNotEmpty;
        if (wasEmpty && nowHasData) {
          _syncControllersFromProvider(next);
        }
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXXLarge,
        vertical: AppConstants.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: colors.surfaceBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingLarge),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: Icon(
                      Icons.edit_document,
                      color: colors.accentBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Laporan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Isi nama, NIM, dan data instansi untuk template Word',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLarge,
                0,
                AppConstants.spacingLarge,
                AppConstants.spacingLarge,
              ),
              child: Column(
                children: [
                  Divider(height: 1, color: colors.surfaceBorder),
                  const SizedBox(height: 16),
                  _buildField('Nama Mahasiswa', _namaCtrl),
                  const SizedBox(height: 12),
                  _buildField('NIM', _nimCtrl),
                  const SizedBox(height: 12),
                  _buildField('Program Studi', _prodiCtrl),
                  const SizedBox(height: 12),
                  _buildField('Nama Mitra Industri', _mitraCtrl),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: colors.surfaceBorder),
                  const SizedBox(height: 16),
                  Text(
                    'Nama untuk Tanda Tangan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildField('Nama Mahasiswa (TTD)', _namaMahasiswaCtrl),
                  const SizedBox(height: 12),
                  _buildField('Nama Dosen Pembimbing (TTD)', _namaPembimbingCtrl),
                  const SizedBox(height: 12),
                  _buildField('Nama Pembimbing Lapangan (TTD)', _namaPembimbingLapanganCtrl),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Simpan Data'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    final colors = ThemeColors.of(context);

    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: 13,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: colors.textSecondary,
        ),
        filled: true,
        fillColor: colors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: BorderSide(
            color: colors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: BorderSide(
            color: colors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: BorderSide(
            color: colors.accentBlue,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

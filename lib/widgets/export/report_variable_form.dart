import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
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
  late TextEditingController _pembimbingCtrl;
  late TextEditingController _pembimbingLapanganCtrl;
  late TextEditingController _namaMahasiswaCtrl;
  late TextEditingController _namaPembimbingCtrl;
  late TextEditingController _namaPembimbingLapanganCtrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final vars = ref.read(reportVariablesProvider);
    _namaCtrl = TextEditingController(text: vars.nama);
    _nimCtrl = TextEditingController(text: vars.nim);
    _prodiCtrl = TextEditingController(text: vars.prodi);
    _mitraCtrl = TextEditingController(text: vars.mitra);
    _pembimbingCtrl = TextEditingController(text: vars.pembimbing);
    _pembimbingLapanganCtrl = TextEditingController(text: vars.pembimbingLapangan);
    _namaMahasiswaCtrl = TextEditingController(text: vars.namaMahasiswa);
    _namaPembimbingCtrl = TextEditingController(text: vars.namaPembimbing);
    _namaPembimbingLapanganCtrl = TextEditingController(text: vars.namaPembimbingLapangan);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nimCtrl.dispose();
    _prodiCtrl.dispose();
    _mitraCtrl.dispose();
    _pembimbingCtrl.dispose();
    _pembimbingLapanganCtrl.dispose();
    _namaMahasiswaCtrl.dispose();
    _namaPembimbingCtrl.dispose();
    _namaPembimbingLapanganCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(reportVariablesProvider.notifier).update(
      nama: _namaCtrl.text,
      nim: _nimCtrl.text,
      prodi: _prodiCtrl.text,
      mitra: _mitraCtrl.text,
      pembimbing: _pembimbingCtrl.text,
      pembimbingLapangan: _pembimbingLapanganCtrl.text,
      namaMahasiswa: _namaMahasiswaCtrl.text,
      namaPembimbing: _namaPembimbingCtrl.text,
      namaPembimbingLapangan: _namaPembimbingLapanganCtrl.text,
    );
    ref.read(reportVariablesProvider.notifier).save();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data instansi berhasil disimpan.'),
        backgroundColor: AppColors.accentGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingXXLarge,
        vertical: AppConstants.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: AppColors.surfaceBorder.withValues(alpha: 0.5),
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
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.edit_document,
                      color: AppColors.accentBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Laporan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Isi nama, NIM, dan data instansi untuk template Word',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
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
                  const Divider(height: 1, color: AppColors.surfaceBorder),
                  const SizedBox(height: 16),
                  _buildField('Nama Mahasiswa', _namaCtrl),
                  const SizedBox(height: 12),
                  _buildField('NIM', _nimCtrl),
                  const SizedBox(height: 12),
                  _buildField('Program Studi', _prodiCtrl),
                  const SizedBox(height: 12),
                  _buildField('Nama Mitra Industri', _mitraCtrl),
                  const SizedBox(height: 12),
                  _buildField('Dosen Pembimbing', _pembimbingCtrl),
                  const SizedBox(height: 12),
                  _buildField('Pembimbing Lapangan', _pembimbingLapanganCtrl),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.surfaceBorder),
                  const SizedBox(height: 16),
                  const Text(
                    'Nama untuk Tanda Tangan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: BorderSide(
            color: AppColors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: BorderSide(
            color: AppColors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.accentBlue,
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

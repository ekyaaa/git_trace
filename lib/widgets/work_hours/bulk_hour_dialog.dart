import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';

class BulkHourDialog extends StatefulWidget {
  final int month;
  final int year;
  final Future<void> Function(String checkIn, String checkOut, bool weekdaysOnly)
      onSave;

  const BulkHourDialog({
    super.key,
    required this.month,
    required this.year,
    required this.onSave,
  });

  @override
  State<BulkHourDialog> createState() => _BulkHourDialogState();
}

class _BulkHourDialogState extends State<BulkHourDialog> {
  final _checkInController =
      TextEditingController(text: AppConstants.defaultCheckIn);
  final _checkOutController =
      TextEditingController(text: AppConstants.defaultCheckOut);
  bool _weekdaysOnly = true;
  bool _saving = false;

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.date_range,
              color: AppColors.accentPurple, size: 18),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atur Jam Kerja Massal',
                style: TextStyle(fontSize: 16)),
            Text('Set jam untuk seluruh bulan',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ]),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _checkInController,
              decoration: const InputDecoration(
                labelText: 'Jam Masuk',
                prefixIcon: Icon(Icons.login, size: 18),
                hintText: 'HH.MM',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _checkOutController,
              decoration: const InputDecoration(
                labelText: 'Jam Pulang',
                prefixIcon: Icon(Icons.logout, size: 18),
                hintText: 'HH.MM',
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Hanya hari kerja (Senin-Jumat)',
                  style: TextStyle(fontSize: 13)),
              value: _weekdaysOnly,
              onChanged: (v) => setState(() => _weekdaysOnly = v ?? true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Terapkan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final checkIn = _checkInController.text.trim();
    final checkOut = _checkOutController.text.trim();

    if (!checkIn.isValidTimeFormat || !checkOut.isValidTimeFormat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format waktu harus HH.MM (contoh: 08.00)'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await widget.onSave(checkIn, checkOut, _weekdaysOnly);
    setState(() => _saving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam kerja berhasil diterapkan!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }
}

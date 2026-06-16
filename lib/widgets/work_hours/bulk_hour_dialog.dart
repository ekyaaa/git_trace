import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme_colors.dart';
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
    final colors = ThemeColors.of(context);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        side: BorderSide(
          color: colors.surfaceBorder.withValues(alpha: 0.6),
        ),
      ),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.accentPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: colors.accentPurple.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(Icons.date_range,
              color: colors.accentPurple, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Atur Jam Kerja Massal',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: colors.textPrimary,
                  )),
              const SizedBox(height: 2),
              Text('Set jam untuk seluruh bulan',
                  style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1)),
            ],
          ),
        ),
      ]),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _checkInController,
              decoration: InputDecoration(
                labelText: 'Jam Masuk',
                prefixIcon: const Icon(Icons.login, size: 18),
                hintText: 'HH.MM',
                helperText: 'Contoh: 08.00',
                helperStyle: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _checkOutController,
              decoration: InputDecoration(
                labelText: 'Jam Pulang',
                prefixIcon: const Icon(Icons.logout, size: 18),
                hintText: 'HH.MM',
                helperText: 'Contoh: 17.00',
                helperStyle: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text('Hanya hari kerja (Senin-Jumat)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  )),
              subtitle: Text(
                'Abaikan hari Sabtu & Minggu',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
              value: _weekdaysOnly,
              onChanged: (v) => setState(() => _weekdaysOnly = v ?? true),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: colors.accentPurple,
              checkColor: Colors.white,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Batal'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.accentPurple,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Terapkan'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final colors = ThemeColors.of(context);
    final checkIn = _checkInController.text.trim();
    final checkOut = _checkOutController.text.trim();

    if (!checkIn.isValidTimeFormat || !checkOut.isValidTimeFormat) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Format waktu harus HH.MM (contoh: 08.00)'),
          backgroundColor: colors.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
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
        SnackBar(
          content: const Text('Jam kerja berhasil diterapkan!'),
          backgroundColor: colors.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
        ),
      );
    }
  }
}

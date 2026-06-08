import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../providers/work_hours_provider.dart';
import 'package:intl/intl.dart';

class WorkHoursDialog extends ConsumerStatefulWidget {
  final DateTime date;
  final String? currentCheckIn;
  final String? currentCheckOut;

  const WorkHoursDialog({
    super.key,
    required this.date,
    this.currentCheckIn,
    this.currentCheckOut,
  });

  @override
  ConsumerState<WorkHoursDialog> createState() => _WorkHoursDialogState();
}

class _WorkHoursDialogState extends ConsumerState<WorkHoursDialog> {
  late TextEditingController _checkInController;
  late TextEditingController _checkOutController;

  @override
  void initState() {
    super.initState();
    _checkInController = TextEditingController(
        text: widget.currentCheckIn ?? AppConstants.defaultCheckIn);
    _checkOutController = TextEditingController(
        text: widget.currentCheckOut ?? AppConstants.defaultCheckOut);
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(widget.date);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.schedule,
                color: AppColors.accentBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jam Kerja', style: TextStyle(fontSize: 16)),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TimeField(
              label: 'Jam Masuk',
              controller: _checkInController,
              icon: Icons.login,
            ),
            const SizedBox(height: 16),
            _TimeField(
              label: 'Jam Pulang',
              controller: _checkOutController,
              icon: Icons.logout,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentCheckIn != null)
          TextButton(
            onPressed: _deleteHours,
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.accentRed)),
          ),
        const Spacer(),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveHours,
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _saveHours() {
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

    final dateKey = widget.date.isoDateString;
    ref.read(workHoursProvider.notifier).setHours(dateKey, checkIn, checkOut);
    Navigator.pop(context);
  }

  void _deleteHours() {
    final dateKey = widget.date.isoDateString;
    ref.read(workHoursProvider.notifier).removeHours(dateKey);
    Navigator.pop(context);
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  const _TimeField({
    required this.label,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        hintText: 'HH.MM',
      ),
    );
  }
}

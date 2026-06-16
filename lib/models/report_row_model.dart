class ReportRowModel {
  final String dateKey; // "2026-01-13"
  final String dayDate; // "Senin, 13 Jan 2026"
  final String checkIn; // "08.00"
  final String checkOut; // "17.00"
  final String kegiatan; // "[repo] message\n[repo] message"

  const ReportRowModel({
    this.dateKey = '',
    required this.dayDate,
    required this.checkIn,
    required this.checkOut,
    required this.kegiatan,
  });

  @override
  String toString() =>
      'ReportRowModel(dateKey: $dateKey, date: $dayDate, kegiatan: $kegiatan)';
}

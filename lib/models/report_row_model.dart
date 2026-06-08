class ReportRowModel {
  final String dayDate; // "Senin, 13 Jan 2026"
  final String checkIn; // "08.00"
  final String checkOut; // "17.00"
  final String kegiatan; // "[repo] message\n[repo] message"

  const ReportRowModel({
    required this.dayDate,
    required this.checkIn,
    required this.checkOut,
    required this.kegiatan,
  });

  @override
  String toString() =>
      'ReportRowModel(date: $dayDate, kegiatan: $kegiatan)';
}

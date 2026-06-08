import 'commit_model.dart';

class WorkDayModel {
  final DateTime date;
  final String checkIn;
  final String checkOut;
  final List<CommitModel> commits;

  const WorkDayModel({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    this.commits = const [],
  });

  WorkDayModel copyWith({
    DateTime? date,
    String? checkIn,
    String? checkOut,
    List<CommitModel>? commits,
  }) {
    return WorkDayModel(
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      commits: commits ?? this.commits,
    );
  }

  bool get hasWorkHours => checkIn.isNotEmpty && checkOut.isNotEmpty;

  @override
  String toString() =>
      'WorkDayModel(date: $date, checkIn: $checkIn, checkOut: $checkOut, commits: ${commits.length})';
}

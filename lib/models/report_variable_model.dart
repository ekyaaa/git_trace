class ReportVariableModel {
  final String nama;
  final String nim;
  final String prodi;
  final String mitra;
  final String namaMahasiswa;
  final String namaPembimbing;
  final String namaPembimbingLapangan;
  final String? customTemplatePath;

  ReportVariableModel({
    this.nama = '',
    this.nim = '',
    this.prodi = '',
    this.mitra = '',
    this.namaMahasiswa = '',
    this.namaPembimbing = '',
    this.namaPembimbingLapangan = '',
    this.customTemplatePath,
  });

  ReportVariableModel copyWith({
    String? nama,
    String? nim,
    String? prodi,
    String? mitra,
    String? namaMahasiswa,
    String? namaPembimbing,
    String? namaPembimbingLapangan,
    String? customTemplatePath,
  }) {
    return ReportVariableModel(
      nama: nama ?? this.nama,
      nim: nim ?? this.nim,
      prodi: prodi ?? this.prodi,
      mitra: mitra ?? this.mitra,
      namaMahasiswa: namaMahasiswa ?? this.namaMahasiswa,
      namaPembimbing: namaPembimbing ?? this.namaPembimbing,
      namaPembimbingLapangan: namaPembimbingLapangan ?? this.namaPembimbingLapangan,
      customTemplatePath: customTemplatePath ?? this.customTemplatePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'nim': nim,
      'prodi': prodi,
      'mitra': mitra,
      'namaMahasiswa': namaMahasiswa,
      'namaPembimbing': namaPembimbing,
      'namaPembimbingLapangan': namaPembimbingLapangan,
      'customTemplatePath': customTemplatePath,
    };
  }

  factory ReportVariableModel.fromJson(Map<String, dynamic> json) {
    return ReportVariableModel(
      nama: json['nama'] ?? '',
      nim: json['nim'] ?? '',
      prodi: json['prodi'] ?? '',
      mitra: json['mitra'] ?? '',
      namaMahasiswa: json['namaMahasiswa'] ?? '',
      namaPembimbing: json['namaPembimbing'] ?? '',
      namaPembimbingLapangan: json['namaPembimbingLapangan'] ?? '',
      customTemplatePath: json['customTemplatePath'],
    );
  }

  bool get isFilled {
    return nama.isNotEmpty &&
        nim.isNotEmpty &&
        prodi.isNotEmpty &&
        mitra.isNotEmpty;
  }
}

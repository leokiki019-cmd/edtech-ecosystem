/// Programme panel headings exactly as printed on the CTTC admissions flyer.
class Department {
  const Department({
    required this.id,
    required this.collegeId,
    required this.name,
    required this.code,
    required this.category,
    required this.durationMonths,
    this.createdAt,
  });

  final String id;
  final String collegeId;
  final String name;
  final String code;
  final String category;
  final int durationMonths;
  final DateTime? createdAt;

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      collegeId: json['collegeId'] as String? ?? '',
      name: json['name'] as String,
      code: json['code'] as String,
      category: json['category'] as String? ?? '3 Years',
      durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 36,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  /// Program length label, e.g. "3-year program" / "6-month course".
  String get durationLabel => durationMonths >= 12
      ? '${durationMonths ~/ 12}-year program'
      : '$durationMonths-month course';

  /// Short badge text for the tile corner, e.g. "3Y", "6M".
  String get durationBadge => durationMonths >= 12
      ? '${durationMonths ~/ 12}Y'
      : '${durationMonths}M';

  /// Short courses and paramedical tiles get the highlight treatment.
  bool get isShortCourse => durationMonths < 12;
}

class College {
  const College({
    required this.id,
    required this.name,
    required this.shortName,
    required this.departments,
    this.createdAt,
  });

  final String id;
  final String name;
  final String shortName;
  final List<Department> departments;
  final DateTime? createdAt;

  int get departmentCount => departments.length;

  /// Departments grouped by flyer panel, in the order the panels are printed.
  Map<String, List<Department>> get departmentsByCategory {
    const order = ['3 Years', '2 Years', '6 Months', '2 Years Paramedical'];
    final groups = <String, List<Department>>{};
    for (final dept in departments) {
      groups.putIfAbsent(dept.category, () => []).add(dept);
    }
    // Print known panels first, then any custom categories the API adds.
    return {
      for (final cat in [...order, ...groups.keys.where((c) => !order.contains(c))])
        if (groups.containsKey(cat)) cat: groups[cat]!,
      };
  }

  factory College.fromJson(Map<String, dynamic> json) {
    final rawDepartments = json['departments'] as List<dynamic>? ?? const [];
    return College(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String? ?? '',
      departments: rawDepartments
          .map((item) => Department.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  /// Fallback used when the API is unreachable, mirroring the demo-data
  /// pattern used by the rest of [ApiService].
  static const College demo = College(
    id: 'col-cttc',
    name: 'Christian Technical Training Center',
    shortName: 'CTTC',
    departments: [
      // 3 YEARS PROGRAMMES (Matric Science)
      Department(id: 'dept-arc', collegeId: 'col-cttc', name: 'Architecture', code: 'ARC', category: '3 Years', durationMonths: 36),
      Department(id: 'dept-civ', collegeId: 'col-cttc', name: 'Civil Engineering Technology', code: 'CIV', category: '3 Years', durationMonths: 36),
      Department(id: 'dept-cit', collegeId: 'col-cttc', name: 'Computer Info Tech.', code: 'CIT', category: '3 Years', durationMonths: 36),
      Department(id: 'dept-eee', collegeId: 'col-cttc', name: 'Electrical Technology', code: 'EEE', category: '3 Years', durationMonths: 36),
      Department(id: 'dept-ece', collegeId: 'col-cttc', name: 'Electronics Technology', code: 'ECE', category: '3 Years', durationMonths: 36),
      Department(id: 'dept-mec', collegeId: 'col-cttc', name: 'Mechanical', code: 'MEC', category: '3 Years', durationMonths: 36),
      // 2 YEARS PROGRAMMES (Matric)
      Department(id: 'dept-adm', collegeId: 'col-cttc', name: 'Auto & Diesel Mechanic', code: 'ADM', category: '2 Years', durationMonths: 24),
      Department(id: 'dept-dft', collegeId: 'col-cttc', name: 'Drafting Civil', code: 'DFT', category: '2 Years', durationMonths: 24),
      Department(id: 'dept-elc', collegeId: 'col-cttc', name: 'Electrician', code: 'ELC', category: '2 Years', durationMonths: 24),
      // 6 MONTHS PROGRAMMES (Middle)
      Department(id: 'dept-cnc', collegeId: 'col-cttc', name: 'CNC Programmer', code: 'CNC', category: '6 Months', durationMonths: 6),
      Department(id: 'dept-mac', collegeId: 'col-cttc', name: 'Machinist', code: 'MAC', category: '6 Months', durationMonths: 6),
      Department(id: 'dept-aec', collegeId: 'col-cttc', name: 'Auto Electrician', code: 'AEC', category: '6 Months', durationMonths: 6),
      // 2 YEARS PARAMEDICAL COURSES (Punjab Medical Faculty)
      Department(id: 'dept-ott', collegeId: 'col-cttc', name: 'FSc. Operation Theatre Technology', code: 'OTT', category: '2 Years Paramedical', durationMonths: 24),
      Department(id: 'dept-rad', collegeId: 'col-cttc', name: 'FSc. Radiography & Medical Imaging Technology', code: 'RAD', category: '2 Years Paramedical', durationMonths: 24),
      Department(id: 'dept-mlt', collegeId: 'col-cttc', name: 'FSc. Medical Laboratory Technology', code: 'MLT', category: '2 Years Paramedical', durationMonths: 24),
      Department(id: 'dept-dsp', collegeId: 'col-cttc', name: 'FSc. Dispensing Technology', code: 'DSP', category: '2 Years Paramedical', durationMonths: 24),
      Department(id: 'dept-ane', collegeId: 'col-cttc', name: 'Anesthesia Technician', code: 'ANE', category: '2 Years Paramedical', durationMonths: 24),
      Department(id: 'dept-pht', collegeId: 'col-cttc', name: 'Public Health Technician', code: 'PHT', category: '2 Years Paramedical', durationMonths: 24),
    ],
  );
}

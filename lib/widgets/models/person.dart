class Person {
  final String name;
  final String profilePath;
  final int id;
  String? department;

  Person({
    required this.name,
    required this.profilePath,
    required this.id,
    this.department,
  });
}

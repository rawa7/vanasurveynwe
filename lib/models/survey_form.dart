class SurveyForm {
  final int id;
  final String title;
  final String createdAt;

  SurveyForm({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory SurveyForm.fromJson(Map<String, dynamic> json) {
    return SurveyForm(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt,
    };
  }
}
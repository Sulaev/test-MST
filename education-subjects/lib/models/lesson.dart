class Lesson {
  final String id;
  final String subject;
  final String title;
  final String description;
  final String content;
  final int order;

  Lesson({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.content,
    required this.order,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      subject: json['subject'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      content: json['content'] as String,
      order: json['order'] as int,
    );
  }
}

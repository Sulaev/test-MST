class Question {
  final String id;
  final String subject;
  final String question;
  final List<String> answers;
  final int correctAnswer;
  final String? explanation;

  Question({
    required this.id,
    required this.subject,
    required this.question,
    required this.answers,
    required this.correctAnswer,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      subject: json['subject'] as String,
      question: json['question'] as String,
      answers: List<String>.from(json['answers'] as List),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String?,
    );
  }
}

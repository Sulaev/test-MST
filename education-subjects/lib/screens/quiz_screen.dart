import 'package:flutter/material.dart';

import '../models/question.dart';
import '../services/education_service.dart';
import '../services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.subject});

  final String? subject;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = <Question>[];
  int _score = 0;
  int _currentQuestion = 0;
  List<int> _selectedAnswers = <int>[];
  bool _showExplanation = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    final source = widget.subject != null
        ? EducationService.getQuestionsBySubject(widget.subject!)
        : EducationService.getAllQuestions();

    setState(() {
      _questions = List<Question>.from(source)..shuffle();
      _score = 0;
      _currentQuestion = 0;
      _selectedAnswers = List<int>.filled(_questions.length, -1);
      _showExplanation = false;
    });
  }

  void _answerQuestion(int index) {
    final question = _questions[_currentQuestion];
    final isCorrect = index == question.correctAnswer;

    setState(() {
      _selectedAnswers[_currentQuestion] = index;
      _showExplanation = true;
      if (isCorrect) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _showExplanation = false;
      });
      return;
    }

    _showResult();
  }

  String _resultEmoji(int percentage) {
    if (percentage == 100) return ':D';
    if (percentage >= 80) return ':)';
    if (percentage >= 60) return ':|';
    return ':(';
  }

  String _resultMessage(int percentage) {
    if (percentage == 100) return 'Perfect! You answered every question correctly.';
    if (percentage >= 80) return 'Great work! You are doing very well.';
    if (percentage >= 60) return 'Good result. Keep practicing to level up.';
    return 'Nice try. Practice a little more and retry.';
  }

  Future<void> _showResult() async {
    final correctBySubject = <String, int>{};
    final totalBySubject = <String, int>{};

    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selected = _selectedAnswers[i];
      totalBySubject[q.subject] = (totalBySubject[q.subject] ?? 0) + 1;

      if (selected == q.correctAnswer) {
        correctBySubject[q.subject] = (correctBySubject[q.subject] ?? 0) + 1;
      }
    }

    await ProgressService.recordQuizAttempt(
      correctBySubject: correctBySubject,
      totalBySubject: totalBySubject,
    );
    if (!mounted) return;

    final percentage = (_score / _questions.length * 100).round();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your score: $_score of ${_questions.length}'),
            const SizedBox(height: 8),
            Text(
              'Result: $percentage%  ${_resultEmoji(percentage)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: percentage >= 80 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(_resultMessage(percentage)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadQuestions();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions available yet.')),
      );
    }

    final question = _questions[_currentQuestion];
    final selectedAnswer = _selectedAnswers[_currentQuestion];
    final isCorrect = selectedAnswer == question.correctAnswer;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Question ${_currentQuestion + 1}/${_questions.length}'),
                            const Spacer(),
                            Chip(
                              label: Text(question.subject),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: (_currentQuestion + 1) / _questions.length),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  question.question,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.builder(
                    itemCount: question.answers.length,
                    itemBuilder: (context, index) {
                      final answer = question.answers[index];
                      final selected = selectedAnswer == index;
                      final isRight = index == question.correctAnswer;

                      Color? background;
                      if (_showExplanation) {
                        if (isRight) {
                          background = Colors.green;
                        } else if (selected) {
                          background = Colors.red;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          onPressed: _showExplanation ? null : () => _answerQuestion(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: background,
                            foregroundColor: background == null ? null : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(answer)),
                              if (_showExplanation && selected)
                                Icon(isCorrect ? Icons.check_circle : Icons.cancel),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_showExplanation)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withValues(alpha: 0.10)
                          : Colors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCorrect ? 'Correct! Great job.' : 'Not quite, keep trying.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                        if (question.explanation != null) ...[
                          const SizedBox(height: 6),
                          Text(question.explanation!),
                        ],
                      ],
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _showExplanation ? _nextQuestion : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _currentQuestion < _questions.length - 1
                        ? 'Next question'
                        : 'Finish quiz',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

import '../models/lesson.dart';
import '../models/question.dart';
import 'logger_service.dart';

class EducationService {
  static const String math = 'Mathematics';
  static const String physics = 'Physics';
  static const String chemistry = 'Chemistry';

  static final List<Lesson> _lessons = [
    Lesson(
      id: 'math_1',
      subject: math,
      title: 'Linear Equations Basics',
      description: 'Learn how to isolate variables and solve one-step and two-step equations.',
      content: '''
A linear equation has the form ax + b = c.

Steps to solve:
1) Move constants to the other side.
2) Divide by the coefficient of x.

Example:
2x + 5 = 15
2x = 10
x = 5

Tip: Always perform the same operation on both sides.
      ''',
      order: 1,
    ),
    Lesson(
      id: 'math_2',
      subject: math,
      title: 'Area and Perimeter',
      description: 'Practice formulas for rectangles, triangles, and circles.',
      content: '''
Common formulas:
Rectangle area: A = width * height
Rectangle perimeter: P = 2(width + height)
Triangle area: A = (base * height) / 2
Circle area: A = pi * r^2

Example:
Rectangle width=6, height=4
A = 24, P = 20
      ''',
      order: 2,
    ),
    Lesson(
      id: 'physics_1',
      subject: physics,
      title: 'Force and Newtons Second Law',
      description: 'Understand the relation between force, mass, and acceleration.',
      content: '''
Newtons second law:
F = m * a

Where:
F = force (newtons)
m = mass (kg)
a = acceleration (m/s^2)

Example:
A 3 kg object accelerates at 2 m/s^2
F = 3 * 2 = 6 N
      ''',
      order: 1,
    ),
    Lesson(
      id: 'physics_2',
      subject: physics,
      title: 'Electric Circuits Basics',
      description: 'Meet current, voltage, resistance, and simple Ohm law tasks.',
      content: '''
Ohm law:
V = I * R

Where:
V = voltage (volts)
I = current (amps)
R = resistance (ohms)

Example:
R = 5 ohm, I = 2 A
V = 10 V
      ''',
      order: 2,
    ),
    Lesson(
      id: 'chem_1',
      subject: chemistry,
      title: 'Atoms, Molecules, and Elements',
      description: 'Build a clear foundation for chemical symbols and formulas.',
      content: '''
Element: one type of atom (O, H, Na)
Molecule: two or more atoms bonded together (H2O, CO2)

Examples:
H2O = water
CO2 = carbon dioxide
O2 = oxygen gas
      ''',
      order: 1,
    ),
    Lesson(
      id: 'chem_2',
      subject: chemistry,
      title: 'Acids and Bases Intro',
      description: 'Learn pH scale and recognize common acid/base examples.',
      content: '''
pH < 7: acid
pH = 7: neutral
pH > 7: base

Examples:
Lemon juice: acidic
Pure water: neutral
Soap solution: basic
      ''',
      order: 2,
    ),
  ];

  static final List<Question> _questions = [
    Question(
      id: 'q1',
      subject: math,
      question: 'Solve: 3x + 6 = 21',
      answers: const ['x = 3', 'x = 5', 'x = 7', 'x = 9'],
      correctAnswer: 1,
      explanation: '3x = 15, so x = 5.',
    ),
    Question(
      id: 'q2',
      subject: math,
      question: 'Area of rectangle 8 by 3 is:',
      answers: const ['11', '16', '24', '28'],
      correctAnswer: 2,
      explanation: 'A = width * height = 8 * 3 = 24.',
    ),
    Question(
      id: 'q3',
      subject: math,
      question: 'Perimeter of square with side 4 is:',
      answers: const ['8', '12', '16', '20'],
      correctAnswer: 2,
      explanation: 'P = 4 * side = 16.',
    ),
    Question(
      id: 'q4',
      subject: physics,
      question: 'If m = 2 kg and a = 4 m/s^2, force is:',
      answers: const ['2 N', '6 N', '8 N', '12 N'],
      correctAnswer: 2,
      explanation: 'F = m * a = 2 * 4 = 8 N.',
    ),
    Question(
      id: 'q5',
      subject: physics,
      question: 'In Ohm law, V equals:',
      answers: const ['I / R', 'I * R', 'R / I', 'I + R'],
      correctAnswer: 1,
      explanation: 'V = I * R.',
    ),
    Question(
      id: 'q6',
      subject: physics,
      question: 'Current unit is:',
      answers: const ['Volt', 'Newton', 'Ampere', 'Watt'],
      correctAnswer: 2,
      explanation: 'Electric current is measured in amperes.',
    ),
    Question(
      id: 'q7',
      subject: chemistry,
      question: 'Water formula is:',
      answers: const ['CO2', 'H2O', 'O2', 'NaCl'],
      correctAnswer: 1,
      explanation: 'Water is H2O.',
    ),
    Question(
      id: 'q8',
      subject: chemistry,
      question: 'pH 3 is:',
      answers: const ['Acidic', 'Neutral', 'Basic', 'Salty'],
      correctAnswer: 0,
      explanation: 'Any pH below 7 is acidic.',
    ),
    Question(
      id: 'q9',
      subject: chemistry,
      question: 'Which is an element symbol?',
      answers: const ['H2O', 'CO2', 'O', 'NaCl'],
      correctAnswer: 2,
      explanation: 'O is an element symbol (oxygen).',
    ),
  ];

  static List<Lesson> getLessonsBySubject(String subject) {
    return _lessons.where((lesson) => lesson.subject == subject).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  static List<String> getSubjects() {
    return [math, physics, chemistry];
  }

  static Lesson? getLessonById(String id) {
    try {
      return _lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      LoggerService.error('Lesson not found: $id', e);
      return null;
    }
  }

  static List<Question> getQuestionsBySubject(String subject) {
    return _questions.where((q) => q.subject == subject).toList();
  }

  static List<Question> getAllQuestions() {
    return List<Question>.from(_questions);
  }
}

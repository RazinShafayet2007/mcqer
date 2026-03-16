import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../features/exams/domain/models.dart';
import 'api_config.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;
}

class ApiClient {
  final http.Client _http = http.Client();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<dynamic> _request(
    String method,
    String path, {
    String? token,
    Object? body,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    late http.Response response;
    final uri = _uri(path);
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        response = await _http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _http.post(uri, headers: headers, body: encodedBody);
        break;
      case 'PATCH':
        response = await _http.patch(uri, headers: headers, body: encodedBody);
        break;
      default:
        throw ApiException('Unsupported request method: $method');
    }

    dynamic data;
    if (response.body.isNotEmpty) {
      data = jsonDecode(response.body);
    }

    if (response.statusCode >= 400) {
      final message = data is Map<String, dynamic>
          ? (data['message'] is List ? (data['message'] as List).join(', ') : data['message'])
          : 'Request failed with status ${response.statusCode}';
      throw ApiException('$message');
    }
    return data;
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    required String username,
  }) async {
    final data = await _request(
      'POST',
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'role': role.name.toUpperCase(),
        'name': name,
        'username': username,
      },
    ) as Map<String, dynamic>;
    return _sessionFromJson(data);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>;
    return _sessionFromJson(data);
  }

  Future<AppUser> me(String token) async {
    final data = await _request('GET', '/me', token: token) as Map<String, dynamic>;
    return _userFromJson(data);
  }

  Future<AppUser> updateProfile(
    String token, {
    required String name,
    required String username,
    required String bio,
    required String headline,
    required String? profileImageUrl,
  }) async {
    final data = await _request(
      'PATCH',
      '/me/profile',
      token: token,
      body: {
        'name': name,
        'username': username,
        'bio': bio,
        'headline': headline,
        'profileImageUrl': profileImageUrl,
      },
    ) as Map<String, dynamic>;
    return AppUser(
      id: data['userId'] as String? ?? '',
      name: data['name'] as String,
      username: data['username'] as String,
      bio: (data['bio'] ?? '') as String,
      profileImagePath: data['profileImageUrl'] as String?,
      headline: (data['headline'] ?? '') as String,
      role: UserRole.examinee,
    );
  }

  Future<String?> uploadProfileImage(String token, String path) async {
    final request = http.MultipartRequest('POST', _uri('/uploads/profile-image'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', path));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException((data['message'] ?? 'Upload failed').toString());
    }
    return data['url'] as String?;
  }

  Future<List<AppUser>> friendSuggestions(String token) async {
    final data = await _request('GET', '/friends/suggestions', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_userFromJson).toList();
  }

  Future<List<FriendRequest>> incomingFriendRequests(String token) async {
    final data = await _request('GET', '/friends/requests/incoming', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_friendRequestFromJson).toList();
  }

  Future<List<AppUser>> friends(String token) async {
    final data = await _request('GET', '/friends', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_userFromJson).toList();
  }

  Future<void> sendFriendRequest(String token, String receiverId) async {
    await _request('POST', '/friends/requests', token: token, body: {'receiverId': receiverId});
  }

  Future<void> acceptFriendRequest(String token, String requestId) async {
    await _request('POST', '/friends/requests/$requestId/accept', token: token);
  }

  Future<List<Exam>> myExams(String token) async {
    final data = await _request('GET', '/exams/my', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map((item) => _examFromJson(item, includeQuestions: true)).toList();
  }

  Future<List<Exam>> availableExams(String token) async {
    final data = await _request('GET', '/exams/available', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map((item) => _examFromJson(item)).toList();
  }

  Future<Exam> createExam(
    String token, {
    required String title,
    required String description,
    required int durationMinutes,
    required double negativeMarkPerWrong,
    required String visibility,
    required List<String> assignedExamineeIds,
  }) async {
    final data = await _request(
      'POST',
      '/exams',
      token: token,
      body: {
        'title': title,
        'description': description,
        'durationMinutes': durationMinutes,
        'negativeMarkPerWrong': negativeMarkPerWrong,
        'visibility': visibility,
        'assignedExamineeIds': assignedExamineeIds,
      },
    ) as Map<String, dynamic>;
    return _examFromJson(data);
  }

  Future<void> importQuestions(String token, String examId, String rawText) async {
    await _request('POST', '/exams/$examId/import-questions', token: token, body: {'rawText': rawText});
  }

  Future<void> publishExam(String token, String examId) async {
    await _request('PATCH', '/exams/$examId/publish', token: token);
  }

  Future<Exam> examDetail(String token, String examId) async {
    final data = await _request('GET', '/exams/$examId', token: token) as Map<String, dynamic>;
    return _examFromJson(data, includeQuestions: true);
  }

  Future<List<ExamineeAttemptHistory>> examResults(String token, String examId) async {
    final data = await _request('GET', '/exams/$examId/results', token: token) as List<dynamic>;
    return data.cast<Map<String, dynamic>>().map(_historyFromJson).toList();
  }

  Future<ExamAttempt> startAttempt(String token, String examId) async {
    final data = await _request('POST', '/attempts/start', token: token, body: {'examId': examId}) as Map<String, dynamic>;
    return _attemptFromJson(data);
  }

  Future<AttemptQuestionSet> attemptQuestions(String token, String attemptId) async {
    final data = await _request('GET', '/attempts/$attemptId/questions', token: token) as Map<String, dynamic>;
    return AttemptQuestionSet.fromJson(data);
  }

  Future<void> saveAnswer(String token, String attemptId, String questionId, int optionIndex) async {
    await _request(
      'POST',
      '/attempts/$attemptId/answer',
      token: token,
      body: {
        'questionId': questionId,
        'selectedOption': 'ABCD'[optionIndex],
      },
    );
  }

  Future<AttemptResultData> submitAttempt(String token, String attemptId) async {
    await _request('POST', '/attempts/$attemptId/submit', token: token);
    return attemptResult(token, attemptId);
  }

  Future<AttemptResultData> attemptResult(String token, String attemptId) async {
    final data = await _request('GET', '/attempts/$attemptId/result', token: token) as Map<String, dynamic>;
    return AttemptResultData.fromJson(data);
  }

  AuthSession _sessionFromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: _userFromJson(json['user'] as Map<String, dynamic>),
    );
  }

  AppUser _userFromJson(Map<String, dynamic> json) {
    final profile = (json['profile'] as Map<String, dynamic>?) ?? json;
    return AppUser(
      id: (json['id'] ?? profile['userId']) as String,
      name: (profile['name'] ?? '') as String,
      username: (profile['username'] ?? '') as String,
      bio: (profile['bio'] ?? '') as String,
      profileImagePath: profile['profileImageUrl'] as String?,
      headline: (profile['headline'] ?? '') as String,
      role: ((json['role'] ?? 'EXAMINEE') as String).toLowerCase() == 'examiner' ? UserRole.examiner : UserRole.examinee,
    );
  }

  FriendRequest _friendRequestFromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      status: (json['status'] as String) == 'ACCEPTED' ? FriendRequestStatus.accepted : FriendRequestStatus.pending,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sender: json['sender'] == null ? null : _userFromJson(json['sender'] as Map<String, dynamic>),
      receiver: json['receiver'] == null ? null : _userFromJson(json['receiver'] as Map<String, dynamic>),
    );
  }

  Exam _examFromJson(Map<String, dynamic> json, {bool includeQuestions = false}) {
    final assignments = (json['assignments'] as List<dynamic>?) ?? const [];
    final questionsJson = (json['questions'] as List<dynamic>?) ?? const [];
    final creator = json['createdBy'] as Map<String, dynamic>?;
    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] ?? '') as String,
      durationMinutes: json['durationMinutes'] as int,
      negativeMarkPerWrong: (json['negativeMarkPerWrong'] as num).toDouble(),
      createdBy: creator == null ? '' : (((creator['profile'] as Map<String, dynamic>?)?['name']) ?? (creator['email'] ?? '')) as String,
      isPublished: (json['isPublished'] ?? false) as bool,
      questions: includeQuestions
          ? questionsJson.cast<Map<String, dynamic>>().asMap().entries.map((entry) {
              final q = entry.value;
              final options = [
                (q['optionA'] ?? q['options']?['A'] ?? '') as String,
                (q['optionB'] ?? q['options']?['B'] ?? '') as String,
                (q['optionC'] ?? q['options']?['C'] ?? '') as String,
                (q['optionD'] ?? q['options']?['D'] ?? '') as String,
              ];
              final correctRaw = q['correctOption'] as String?;
              return ExamQuestion(
                id: q['id'] as String,
                prompt: (q['questionText'] ?? '') as String,
                options: options,
                correctIndex: correctRaw == null ? -1 : 'ABCD'.indexOf(correctRaw),
              );
            }).toList()
          : const [],
      highlight: const [0xFFF4C66D, 0xFFFF8A65],
      assignedExamineeIds: assignments.map((item) => (item as Map<String, dynamic>)['examineeId'] as String).toList(),
    );
  }

  ExamAttempt _attemptFromJson(Map<String, dynamic> json) {
    return ExamAttempt(
      id: json['id'] as String,
      examId: json['examId'] as String,
      examineeId: json['examineeId'] as String? ?? '',
      examineeName: '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
      answers: const {},
      status: _attemptStatusFromString((json['status'] ?? 'IN_PROGRESS') as String),
    );
  }

  ExamineeAttemptHistory _historyFromJson(Map<String, dynamic> json) {
    final attempts = (json['attempts'] as List<dynamic>).cast<Map<String, dynamic>>().map(_attemptFromJson).toList();
    final latest = _attemptFromJson(json['latestAttempt'] as Map<String, dynamic>);
    final latestScore = ((json['latestAttempt'] as Map<String, dynamic>)['finalScore'] as num).toDouble();
    return ExamineeAttemptHistory(
      examineeName: ((json['examinee'] as Map<String, dynamic>?)?['name'] ?? '') as String,
      attempts: attempts,
      latestAttempt: latest,
      latestSummary: AttemptSummary(
        correctCount: (json['latestAttempt']['correctCount'] ?? 0) as int,
        wrongCount: (json['latestAttempt']['wrongCount'] ?? 0) as int,
        unansweredCount: (json['latestAttempt']['unansweredCount'] ?? 0) as int,
        negativeDeduction: ((json['latestAttempt']['negativeMarks'] ?? 0) as num).toDouble(),
        finalScore: latestScore,
      ),
      bestScore: (json['bestScore'] as num).toDouble(),
    );
  }
}

AttemptStatus _attemptStatusFromString(String status) {
  switch (status) {
    case 'COMPLETED':
      return AttemptStatus.completed;
    case 'AUTO_SUBMITTED':
      return AttemptStatus.autoSubmitted;
    case 'SUBMITTED':
      return AttemptStatus.submitted;
    default:
      return AttemptStatus.inProgress;
  }
}

class AttemptQuestionSet {
  AttemptQuestionSet({
    required this.attempt,
    required this.questions,
  });

  final ExamAttempt attempt;
  final List<ExamQuestion> questions;

  factory AttemptQuestionSet.fromJson(Map<String, dynamic> json) {
    return AttemptQuestionSet(
      attempt: ExamAttempt(
        id: json['attemptId'] as String,
        examId: '',
        examineeId: '',
        examineeName: '',
        startedAt: DateTime.parse(json['startedAt'] as String),
        endAt: DateTime.parse(json['endAt'] as String),
        answers: {
          for (final item in (json['questions'] as List<dynamic>).cast<Map<String, dynamic>>())
            if (item['selectedOption'] != null)
              item['id'] as String: 'ABCD'.indexOf(item['selectedOption'] as String),
        },
        status: _attemptStatusFromString(json['status'] as String),
      ),
      questions: (json['questions'] as List<dynamic>).cast<Map<String, dynamic>>().map((item) {
        return ExamQuestion(
          id: item['id'] as String,
          prompt: item['questionText'] as String,
          options: [
            item['options']['A'] as String,
            item['options']['B'] as String,
            item['options']['C'] as String,
            item['options']['D'] as String,
          ],
          correctIndex: -1,
        );
      }).toList(),
    );
  }
}

class AttemptResultData {
  AttemptResultData({
    required this.attempt,
    required this.summary,
    required this.questions,
  });

  final ExamAttempt attempt;
  final AttemptSummary summary;
  final List<ExamQuestionResult> questions;

  factory AttemptResultData.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>;
    final questions = (json['questions'] as List<dynamic>).cast<Map<String, dynamic>>().map(ExamQuestionResult.fromJson).toList();
    return AttemptResultData(
      attempt: ExamAttempt(
        id: json['id'] as String,
        examId: json['examId'] as String,
        examineeId: '',
        examineeName: '',
        startedAt: DateTime.parse(json['startedAt'] as String),
        endAt: DateTime.parse((json['submittedAt'] ?? json['startedAt']) as String),
        answers: {
          for (final question in questions)
            if (question.selectedIndex != null) question.id: question.selectedIndex!,
        },
        status: _attemptStatusFromString(json['status'] as String),
      ),
      summary: AttemptSummary(
        correctCount: summaryJson['correctCount'] as int,
        wrongCount: summaryJson['wrongCount'] as int,
        unansweredCount: summaryJson['unansweredCount'] as int,
        negativeDeduction: (summaryJson['negativeMarks'] as num).toDouble(),
        finalScore: (summaryJson['finalScore'] as num).toDouble(),
      ),
      questions: questions,
    );
  }
}

class ExamQuestionResult {
  ExamQuestionResult({
    required this.id,
    required this.prompt,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int? selectedIndex;
  final int correctIndex;
  final bool? isCorrect;

  factory ExamQuestionResult.fromJson(Map<String, dynamic> json) {
    return ExamQuestionResult(
      id: json['id'] as String,
      prompt: json['questionText'] as String,
      options: [
        json['options']['A'] as String,
        json['options']['B'] as String,
        json['options']['C'] as String,
        json['options']['D'] as String,
      ],
      selectedIndex: json['selectedOption'] == null ? null : 'ABCD'.indexOf(json['selectedOption'] as String),
      correctIndex: 'ABCD'.indexOf(json['correctOption'] as String),
      isCorrect: json['isCorrect'] as bool?,
    );
  }
}

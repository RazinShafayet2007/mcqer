import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'mock_exam_parser.dart';

final appStateProvider = StateNotifierProvider<AppController, AppState>((ref) {
  return AppController();
});

class AppState {
  const AppState({
    required this.role,
    required this.entryRole,
    required this.currentUserId,
    required this.displayName,
    required this.users,
    required this.friendRequests,
    required this.exams,
    required this.attempts,
    required this.parserDrafts,
  });

  final UserRole? role;
  final UserRole? entryRole;
  final String? currentUserId;
  final String displayName;
  final List<AppUser> users;
  final List<FriendRequest> friendRequests;
  final List<Exam> exams;
  final List<ExamAttempt> attempts;
  final List<ParsedQuestionDraft> parserDrafts;

  AppState copyWith({
    UserRole? role,
    UserRole? entryRole,
    String? currentUserId,
    String? displayName,
    List<AppUser>? users,
    List<FriendRequest>? friendRequests,
    List<Exam>? exams,
    List<ExamAttempt>? attempts,
    List<ParsedQuestionDraft>? parserDrafts,
    bool clearRole = false,
    bool clearEntryRole = false,
    bool clearCurrentUser = false,
  }) {
    return AppState(
      role: clearRole ? null : (role ?? this.role),
      entryRole: clearEntryRole ? null : (entryRole ?? this.entryRole),
      currentUserId: clearCurrentUser ? null : (currentUserId ?? this.currentUserId),
      displayName: displayName ?? this.displayName,
      users: users ?? this.users,
      friendRequests: friendRequests ?? this.friendRequests,
      exams: exams ?? this.exams,
      attempts: attempts ?? this.attempts,
      parserDrafts: parserDrafts ?? this.parserDrafts,
    );
  }

  factory AppState.initial() => AppState(
        role: null,
        entryRole: null,
        currentUserId: null,
        displayName: '',
        users: _seedUsers,
        friendRequests: _seedFriendRequests,
        exams: _seedExams,
        attempts: const [],
        parserDrafts: const [],
      );
}

class AppController extends StateNotifier<AppState> {
  AppController() : super(AppState.initial());

  final _parser = MockExamParser();

  void chooseRole(UserRole role) {
    state = state.copyWith(role: role, entryRole: role);
  }

  void switchRole(UserRole role) {
    state = state.copyWith(role: role);
  }

  void login(String name) {
    final role = state.role;
    if (role == null) {
      return;
    }

    final normalizedName = name.trim().isEmpty ? 'Aster Candidate' : name.trim();
    AppUser? existing;
    for (final user in state.users) {
      final normalizedHandle = normalizedName.toLowerCase().replaceAll(' ', '');
      if (user.role == role && (user.name.toLowerCase() == normalizedName.toLowerCase() || user.username.toLowerCase() == normalizedHandle || user.username.toLowerCase() == normalizedName.toLowerCase())) {
        existing = user;
        break;
      }
    }

    if (existing != null) {
      state = state.copyWith(
        currentUserId: existing.id,
        displayName: existing.name,
      );
      return;
    }

    final user = AppUser(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      name: normalizedName,
      username: _buildUsername(normalizedName, role),
      bio: role == UserRole.examiner ? 'Creates premium assessments and mentors examinees.' : 'Prepares for the next big exam with focused practice.',
      profileImagePath: null,
      headline: role == UserRole.examiner ? 'Exam strategist' : 'Ambitious examinee',
      role: role,
    );
    state = state.copyWith(
      currentUserId: user.id,
      displayName: user.name,
      users: [...state.users, user],
    );
  }

  void logout() {
    state = state.copyWith(
      displayName: '',
      clearRole: true,
      clearEntryRole: true,
      clearCurrentUser: true,
    );
  }

  void parseQuestions(String raw) {
    state = state.copyWith(parserDrafts: _parser.parse(raw));
  }

  void createExam({
    required String title,
    required String description,
    required int durationMinutes,
    required double negativeMarkPerWrong,
    required List<String> assignedExamineeIds,
  }) {
    if (state.parserDrafts.isEmpty) {
      return;
    }

    final questions = [
      for (var i = 0; i < state.parserDrafts.length; i++)
        ExamQuestion(
          id: 'q-${DateTime.now().microsecondsSinceEpoch}-$i',
          prompt: state.parserDrafts[i].prompt,
          options: state.parserDrafts[i].options,
          correctIndex: state.parserDrafts[i].correctIndex,
        ),
    ];

    final exam = Exam(
      id: 'exam-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      negativeMarkPerWrong: negativeMarkPerWrong,
      createdBy: state.displayName,
      isPublished: false,
      questions: questions,
      highlight: const [0xFFF4C66D, 0xFFFF8A65],
      assignedExamineeIds: assignedExamineeIds,
    );

    state = state.copyWith(
      exams: [exam, ...state.exams],
      parserDrafts: const [],
    );
  }

  void publishExam(String examId) {
    state = state.copyWith(
      exams: [
        for (final exam in state.exams)
          if (exam.id == examId) exam.copyWith(isPublished: true) else exam,
      ],
    );
  }

  ExamAttempt startAttempt(String examId) {
    final exam = examById(examId);
    final user = currentUser;
    final startedAt = DateTime.now();
    final attempt = ExamAttempt(
      id: 'attempt-${startedAt.microsecondsSinceEpoch}',
      examId: examId,
      examineeId: user.id,
      examineeName: state.displayName,
      startedAt: startedAt,
      endAt: startedAt.add(Duration(minutes: exam.durationMinutes)),
      answers: const {},
      status: AttemptStatus.inProgress,
    );

    state = state.copyWith(attempts: [attempt, ...state.attempts]);
    return attempt;
  }

  void answerQuestion(String attemptId, String questionId, int optionIndex) {
    state = state.copyWith(
      attempts: [
        for (final attempt in state.attempts)
          if (attempt.id == attemptId)
            attempt.copyWith(
              answers: {...attempt.answers, questionId: optionIndex},
            )
          else
            attempt,
      ],
    );
  }

  void submitAttempt(String attemptId, {bool auto = false}) {
    state = state.copyWith(
      attempts: [
        for (final attempt in state.attempts)
          if (attempt.id == attemptId)
            attempt.copyWith(
              status: auto ? AttemptStatus.autoSubmitted : AttemptStatus.completed,
            )
          else
            attempt,
      ],
    );
  }

  Exam examById(String id) => state.exams.firstWhere((exam) => exam.id == id);

  ExamAttempt attemptById(String id) => state.attempts.firstWhere((attempt) => attempt.id == id);

  AppUser get currentUser => state.users.firstWhere((user) => user.id == state.currentUserId);

  AppUser userById(String userId) => state.users.firstWhere((user) => user.id == userId);

  List<AppUser> oppositeRoleSuggestions() {
    final current = currentUser;
    return state.users.where((user) {
      if (user.id == current.id || user.role == current.role) {
        return false;
      }
      return !_hasAcceptedFriendship(current.id, user.id);
    }).toList();
  }

  List<FriendRequest> incomingFriendRequests() {
    final currentId = state.currentUserId;
    if (currentId == null) {
      return const [];
    }
    return state.friendRequests
        .where((request) => request.receiverId == currentId && request.status == FriendRequestStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AppUser> acceptedFriends() {
    final currentId = state.currentUserId;
    if (currentId == null) {
      return const [];
    }

    final ids = <String>{};
    for (final request in state.friendRequests) {
      if (request.status != FriendRequestStatus.accepted) {
        continue;
      }
      if (request.senderId == currentId) {
        ids.add(request.receiverId);
      }
      if (request.receiverId == currentId) {
        ids.add(request.senderId);
      }
    }

    return state.users.where((user) => ids.contains(user.id)).toList();
  }

  List<AppUser> acceptedFriendsForRole(UserRole role) {
    return acceptedFriends().where((user) => user.role == role).toList();
  }

  bool hasPendingRequestWith(String otherUserId) {
    final currentId = state.currentUserId;
    if (currentId == null) {
      return false;
    }
    return state.friendRequests.any(
      (request) =>
          request.status == FriendRequestStatus.pending &&
          ((request.senderId == currentId && request.receiverId == otherUserId) ||
              (request.senderId == otherUserId && request.receiverId == currentId)),
    );
  }

  void sendFriendRequest(String receiverId) {
    final currentId = state.currentUserId;
    if (currentId == null || currentId == receiverId) {
      return;
    }
    if (_hasAcceptedFriendship(currentId, receiverId) || hasPendingRequestWith(receiverId)) {
      return;
    }

    final request = FriendRequest(
      id: 'request-${DateTime.now().microsecondsSinceEpoch}',
      senderId: currentId,
      receiverId: receiverId,
      status: FriendRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(friendRequests: [request, ...state.friendRequests]);
  }

  void acceptFriendRequest(String requestId) {
    state = state.copyWith(
      friendRequests: [
        for (final request in state.friendRequests)
          if (request.id == requestId) request.copyWith(status: FriendRequestStatus.accepted) else request,
      ],
    );
  }

  void updateCurrentUserProfile({
    required String name,
    required String username,
    required String bio,
    required String? profileImagePath,
    required String headline,
  }) {
    final currentId = state.currentUserId;
    if (currentId == null) {
      return;
    }

    final normalizedUsername = username.trim().replaceAll(' ', '').toLowerCase();
    state = state.copyWith(
      displayName: name.trim(),
      users: [
        for (final user in state.users)
          if (user.id == currentId)
            user.copyWith(
              name: name.trim(),
              username: normalizedUsername,
              bio: bio.trim(),
              profileImagePath: profileImagePath,
              clearProfileImagePath: profileImagePath == null,
              headline: headline.trim(),
            )
          else
            user,
      ],
    );
  }

  List<Exam> visibleExamsForCurrentUser() {
    final currentId = state.currentUserId;
    if (currentId == null) {
      return const [];
    }
    return state.exams.where((exam) {
      if (!exam.isPublished) {
        return false;
      }
      return exam.assignedExamineeIds.isEmpty || exam.assignedExamineeIds.contains(currentId);
    }).toList();
  }

  ExamAttempt? latestCompletedAttemptForExam(String examId) {
    for (final attempt in state.attempts) {
      if (
          attempt.examId == examId &&
          attempt.examineeId == state.currentUserId &&
          attempt.status != AttemptStatus.inProgress) {
        return attempt;
      }
    }
    return null;
  }

  AttemptSummary summaryForAttempt(String attemptId) {
    final attempt = attemptById(attemptId);
    return summaryForExamAttempt(attempt);
  }

  AttemptSummary summaryForExamAttempt(ExamAttempt attempt) {
    final exam = examById(attempt.examId);
    var correct = 0;
    var wrong = 0;
    var unanswered = 0;

    for (final question in exam.questions) {
      final selected = attempt.answers[question.id];
      if (selected == null) {
        unanswered += 1;
      } else if (selected == question.correctIndex) {
        correct += 1;
      } else {
        wrong += 1;
      }
    }

    final negative = wrong * exam.negativeMarkPerWrong;
    return AttemptSummary(
      correctCount: correct,
      wrongCount: wrong,
      unansweredCount: unanswered,
      negativeDeduction: negative,
      finalScore: correct - negative,
    );
  }

  List<ExamineeAttemptHistory> attemptHistoryForExam(String examId) {
    final histories = <ExamineeAttemptHistory>[];
    final grouped = <String, List<ExamAttempt>>{};

    for (final attempt in state.attempts) {
      if (attempt.examId != examId || attempt.status == AttemptStatus.inProgress) {
        continue;
      }
      grouped.putIfAbsent(attempt.examineeId, () => <ExamAttempt>[]).add(attempt);
    }

    for (final entry in grouped.entries) {
      final attempts = List<ExamAttempt>.from(entry.value)
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      final latestAttempt = attempts.first;
      final latestSummary = summaryForExamAttempt(latestAttempt);
      final bestScore = attempts
          .map(summaryForExamAttempt)
          .map((summary) => summary.finalScore)
          .reduce((a, b) => a > b ? a : b);

      histories.add(
        ExamineeAttemptHistory(
          examineeName: userById(entry.key).name,
          attempts: attempts,
          latestAttempt: latestAttempt,
          latestSummary: latestSummary,
          bestScore: bestScore,
        ),
      );
    }

    histories.sort((a, b) => b.latestAttempt.startedAt.compareTo(a.latestAttempt.startedAt));
    return histories;
  }

  bool isCompleted(String examId) {
    return state.attempts.any(
      (attempt) =>
          attempt.examId == examId &&
          attempt.examineeId == state.currentUserId &&
          attempt.status != AttemptStatus.inProgress,
    );
  }

  bool _hasAcceptedFriendship(String firstUserId, String secondUserId) {
    return state.friendRequests.any(
      (request) =>
          request.status == FriendRequestStatus.accepted &&
          ((request.senderId == firstUserId && request.receiverId == secondUserId) ||
              (request.senderId == secondUserId && request.receiverId == firstUserId)),
    );
  }

  String _buildUsername(String name, UserRole role) {
    final base = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    final prefix = role == UserRole.examiner ? 'examiner' : 'examinee';
    if (base.isEmpty) {
      return '$prefix${state.users.length + 1}';
    }
    return base;
  }
}

final _seedUsers = <AppUser>[
  const AppUser(id: 'examiner-1', name: 'Aster Academy', username: 'asteracademy', bio: 'Builds elegant mock tests and private challenge sets.', profileImagePath: null, headline: 'Assessment architect', role: UserRole.examiner),
  const AppUser(id: 'examiner-2', name: 'Board Office', username: 'boardoffice', bio: 'Publishes official-style papers and timed benchmarks.', profileImagePath: null, headline: 'Official exam curator', role: UserRole.examiner),
  const AppUser(id: 'examinee-1', name: 'Nadia Rahman', username: 'nadiarahman', bio: 'Practising daily with a focus on consistency and speed.', profileImagePath: null, headline: 'Civil service aspirant', role: UserRole.examinee),
  const AppUser(id: 'examinee-2', name: 'Farhan Ali', username: 'farhanali', bio: 'Loves analytics-driven prep and targeted feedback.', profileImagePath: null, headline: 'Data aptitude learner', role: UserRole.examinee),
  const AppUser(id: 'examinee-3', name: 'Mira Sen', username: 'mirasen', bio: 'Preparing for scholarship exams with timed revision blocks.', profileImagePath: null, headline: 'Focused challenger', role: UserRole.examinee),
];

final _seedFriendRequests = <FriendRequest>[
  FriendRequest(
    id: 'request-seed-1',
    senderId: 'examiner-1',
    receiverId: 'examinee-1',
    status: FriendRequestStatus.accepted,
    createdAt: DateTime(2026, 3, 10, 10, 30),
  ),
  FriendRequest(
    id: 'request-seed-2',
    senderId: 'examinee-2',
    receiverId: 'examiner-2',
    status: FriendRequestStatus.pending,
    createdAt: DateTime(2026, 3, 14, 18, 45),
  ),
];

final _seedExams = <Exam>[
  const Exam(
    id: 'exam-civics',
    title: 'Civil Service Sprint',
    description: 'A fast benchmark for polity, current affairs, and logic.',
    durationMinutes: 25,
    negativeMarkPerWrong: 0.25,
    createdBy: 'Board Office',
    isPublished: true,
    highlight: [0xFFF4C66D, 0xFFFF8A65],
    assignedExamineeIds: [],
    questions: [
      ExamQuestion(
        id: 'c1',
        prompt: 'Which article of the Constitution deals with equality before law?',
        options: ['Article 14', 'Article 19', 'Article 21', 'Article 32'],
        correctIndex: 0,
      ),
      ExamQuestion(
        id: 'c2',
        prompt: 'The capital of Australia is:',
        options: ['Sydney', 'Melbourne', 'Canberra', 'Perth'],
        correctIndex: 2,
      ),
      ExamQuestion(
        id: 'c3',
        prompt: 'A statement that must be true if the premises are true is called:',
        options: ['Hypothesis', 'Inference', 'Paradox', 'Axiom'],
        correctIndex: 1,
      ),
    ],
  ),
  const Exam(
    id: 'exam-data',
    title: 'Data Aptitude Crown',
    description: 'Premium analytics-focused practice exam for product and ops roles.',
    durationMinutes: 30,
    negativeMarkPerWrong: 0.25,
    createdBy: 'Aster Academy',
    isPublished: true,
    highlight: [0xFF5ED3A2, 0xFF55A7FF],
    assignedExamineeIds: [],
    questions: [
      ExamQuestion(
        id: 'd1',
        prompt: 'Median of 2, 4, 7, 10, 12 is:',
        options: ['4', '7', '8', '10'],
        correctIndex: 1,
      ),
      ExamQuestion(
        id: 'd2',
        prompt: 'Which chart best shows contribution to a whole?',
        options: ['Scatter plot', 'Pie chart', 'Histogram', 'Area map'],
        correctIndex: 1,
      ),
      ExamQuestion(
        id: 'd3',
        prompt: 'SQL stands for:',
        options: ['Structured Query Language', 'Sequential Query Logic', 'System Query Link', 'Simple Queue Language'],
        correctIndex: 0,
      ),
    ],
  ),
];

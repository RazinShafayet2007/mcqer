import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/session_storage.dart';
import '../domain/models.dart';
import 'mock_exam_parser.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final sessionStorageProvider = Provider<SessionStorage>((ref) => SessionStorage());

final appStateProvider = StateNotifierProvider<AppController, AppState>((ref) {
  return AppController(ref.read(apiClientProvider), ref.read(sessionStorageProvider));
});

class AppState {
  const AppState({
    required this.role,
    required this.entryRole,
    required this.displayName,
    required this.accessToken,
    required this.refreshToken,
    required this.currentUser,
    required this.friendSuggestions,
    required this.incomingRequests,
    required this.friends,
    required this.exams,
    required this.parserDrafts,
    required this.activeAttempt,
    required this.attemptQuestions,
    required this.latestResult,
    required this.examHistories,
    required this.isLoading,
    required this.isRestoringSession,
    required this.errorMessage,
  });

  final UserRole? role;
  final UserRole? entryRole;
  final String displayName;
  final String? accessToken;
  final String? refreshToken;
  final AppUser? currentUser;
  final List<AppUser> friendSuggestions;
  final List<FriendRequest> incomingRequests;
  final List<AppUser> friends;
  final List<Exam> exams;
  final List<ParsedQuestionDraft> parserDrafts;
  final ExamAttempt? activeAttempt;
  final List<ExamQuestion> attemptQuestions;
  final AttemptResultData? latestResult;
  final Map<String, List<ExamineeAttemptHistory>> examHistories;
  final bool isLoading;
  final bool isRestoringSession;
  final String? errorMessage;

  factory AppState.initial() => const AppState(
        role: null,
        entryRole: null,
        displayName: '',
        accessToken: null,
        refreshToken: null,
        currentUser: null,
        friendSuggestions: [],
        incomingRequests: [],
        friends: [],
        exams: [],
        parserDrafts: [],
        activeAttempt: null,
        attemptQuestions: [],
        latestResult: null,
        examHistories: {},
        isLoading: false,
        isRestoringSession: true,
        errorMessage: null,
      );

  AppState copyWith({
    UserRole? role,
    UserRole? entryRole,
    String? displayName,
    String? accessToken,
    String? refreshToken,
    AppUser? currentUser,
    List<AppUser>? friendSuggestions,
    List<FriendRequest>? incomingRequests,
    List<AppUser>? friends,
    List<Exam>? exams,
    List<ParsedQuestionDraft>? parserDrafts,
    ExamAttempt? activeAttempt,
    List<ExamQuestion>? attemptQuestions,
    AttemptResultData? latestResult,
    Map<String, List<ExamineeAttemptHistory>>? examHistories,
    bool? isLoading,
    bool? isRestoringSession,
    String? errorMessage,
    bool clearSession = false,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return AppState(
      role: clearSession ? null : (role ?? this.role),
      entryRole: clearSession ? null : (entryRole ?? this.entryRole),
      displayName: clearSession ? '' : (displayName ?? this.displayName),
      accessToken: clearSession ? null : (accessToken ?? this.accessToken),
      refreshToken: clearSession ? null : (refreshToken ?? this.refreshToken),
      currentUser: clearSession ? null : (currentUser ?? this.currentUser),
      friendSuggestions: friendSuggestions ?? this.friendSuggestions,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      friends: friends ?? this.friends,
      exams: exams ?? this.exams,
      parserDrafts: parserDrafts ?? this.parserDrafts,
      activeAttempt: activeAttempt ?? this.activeAttempt,
      attemptQuestions: attemptQuestions ?? this.attemptQuestions,
      latestResult: clearResult ? null : (latestResult ?? this.latestResult),
      examHistories: examHistories ?? this.examHistories,
      isLoading: isLoading ?? this.isLoading,
      isRestoringSession: isRestoringSession ?? this.isRestoringSession,
      errorMessage: clearError ? null : errorMessage,
    );
  }
}

class AppController extends StateNotifier<AppState> {
  AppController(this._api, this._sessionStorage) : super(AppState.initial());

  final ApiClient _api;
  final SessionStorage _sessionStorage;
  final _parser = MockExamParser();

  void chooseRole(UserRole role) {
    state = state.copyWith(role: role, entryRole: role, clearError: true);
  }

  void switchRole(UserRole role) {
    state = state.copyWith(role: role, clearError: true);
  }

  Future<bool> login(String email, String password) async {
    final result = await _run(() async {
      final session = await _api.login(email: email, password: password);
      await _sessionStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        role: session.user.role,
      );
      state = state.copyWith(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        currentUser: session.user,
        displayName: session.user.name,
        role: session.user.role,
      );
      await loadDashboardData();
      return true;
    });
    return result ?? false;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final role = state.role;
    if (role == null) return false;
    final result = await _run(() async {
      final session = await _api.register(
        email: email,
        password: password,
        role: role,
        name: name,
        username: username,
      );
      await _sessionStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        role: session.user.role,
      );
      state = state.copyWith(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        currentUser: session.user,
        displayName: session.user.name,
        role: session.user.role,
      );
      await loadDashboardData();
      return true;
    });
    return result ?? false;
  }

  Future<void> logout() async {
    final token = state.accessToken;
    if (token != null) {
      try {
        await _api.logout(token);
      } catch (_) {}
    }
    await _sessionStorage.clear();
    state = AppState.initial().copyWith(isRestoringSession: false);
  }

  Future<bool> restoreSession() async {
    final stored = await _sessionStorage.readSession();
    if (stored == null) {
      state = state.copyWith(isRestoringSession: false);
      return false;
    }

    try {
      state = state.copyWith(
        accessToken: stored.accessToken,
        refreshToken: stored.refreshToken,
        role: stored.role,
        entryRole: stored.role,
      );
      final me = await _api.me(stored.accessToken);
      state = state.copyWith(
        currentUser: me,
        displayName: me.name,
        role: me.role,
        entryRole: me.role,
      );
      await loadDashboardData();
      state = state.copyWith(isRestoringSession: false);
      return true;
    } catch (_) {
      try {
        final refreshed = await _api.refresh(stored.refreshToken);
        await _sessionStorage.saveSession(
          accessToken: refreshed.accessToken,
          refreshToken: refreshed.refreshToken,
          role: refreshed.user.role,
        );
        state = state.copyWith(
          accessToken: refreshed.accessToken,
          refreshToken: refreshed.refreshToken,
          currentUser: refreshed.user,
          displayName: refreshed.user.name,
          role: refreshed.user.role,
          entryRole: refreshed.user.role,
        );
        await loadDashboardData();
        state = state.copyWith(isRestoringSession: false);
        return true;
      } catch (_) {
        await _sessionStorage.clear();
        state = AppState.initial().copyWith(isRestoringSession: false);
        return false;
      }
    }
  }

  void parseQuestions(String raw) {
    state = state.copyWith(parserDrafts: _parser.parse(raw), clearError: true);
  }

  Future<void> loadDashboardData() async {
    final token = state.accessToken;
    final role = state.role;
    if (token == null || role == null) return;

    await _run(() async {
      final me = await _api.me(token);
      final suggestions = await _api.friendSuggestions(token);
      final incoming = await _api.incomingFriendRequests(token);
      final friends = await _api.friends(token);
      final exams = role == UserRole.examiner ? await _api.myExams(token) : await _api.availableExams(token);
      state = state.copyWith(
        currentUser: me,
        displayName: me.name,
        friendSuggestions: suggestions,
        incomingRequests: incoming,
        friends: friends,
        exams: exams,
      );
    });
  }

  Future<void> sendFriendRequest(String receiverId) async {
    final token = state.accessToken;
    if (token == null) return;
    await _run(() async {
      await _api.sendFriendRequest(token, receiverId);
      await loadDashboardData();
    });
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final token = state.accessToken;
    if (token == null) return;
    await _run(() async {
      await _api.acceptFriendRequest(token, requestId);
      await loadDashboardData();
    });
  }

  List<AppUser> acceptedFriendsForRole(UserRole role) => state.friends.where((user) => user.role == role).toList();

  AppUser get currentUser => state.currentUser!;

  List<AppUser> oppositeRoleSuggestions() => state.friendSuggestions;

  List<FriendRequest> incomingFriendRequests() => state.incomingRequests;

  List<AppUser> acceptedFriends() => state.friends;

  bool hasPendingRequestWith(String otherUserId) {
    return state.incomingRequests.any((request) => request.senderId == otherUserId || request.receiverId == otherUserId);
  }

  Future<void> createExam({
    required String title,
    required String description,
    required int durationMinutes,
    required double negativeMarkPerWrong,
    required List<String> assignedExamineeIds,
  }) async {
    final token = state.accessToken;
    if (token == null || state.parserDrafts.isEmpty) return;

    await _run(() async {
      final visibility = assignedExamineeIds.isEmpty
          ? 'PUBLIC'
          : assignedExamineeIds.length == acceptedFriendsForRole(UserRole.examinee).length
              ? 'ALL_FRIENDS'
              : 'SELECTED_FRIENDS';
      final exam = await _api.createExam(
        token,
        title: title,
        description: description,
        durationMinutes: durationMinutes,
        negativeMarkPerWrong: negativeMarkPerWrong,
        visibility: visibility,
        assignedExamineeIds: assignedExamineeIds,
      );
      await _api.importQuestions(token, exam.id, _composeRawFromDrafts(state.parserDrafts));
      state = state.copyWith(parserDrafts: []);
      await loadDashboardData();
    });
  }

  Future<void> publishExam(String examId) async {
    final token = state.accessToken;
    if (token == null) return;
    await _run(() async {
      await _api.publishExam(token, examId);
      await loadDashboardData();
    });
  }

  Future<Exam?> refreshExamDetail(String examId) async {
    final token = state.accessToken;
    if (token == null) return null;
    Exam? exam;
    await _run(() async {
      exam = await _api.examDetail(token, examId);
      final updated = [for (final item in state.exams) if (item.id == examId) exam! else item];
      if (!updated.any((item) => item.id == examId) && exam != null) {
        updated.insert(0, exam!);
      }
      Map<String, List<ExamineeAttemptHistory>> histories = state.examHistories;
      if (state.role == UserRole.examiner) {
        final resultHistory = await _api.examResults(token, examId);
        histories = {...state.examHistories, examId: resultHistory};
      }
      state = state.copyWith(exams: updated, examHistories: histories);
    });
    return exam;
  }

  Future<ExamAttempt?> startAttempt(String examId) async {
    final token = state.accessToken;
    if (token == null) return null;
    ExamAttempt? attempt;
    await _run(() async {
      attempt = await _api.startAttempt(token, examId);
      final questionSet = await _api.attemptQuestions(token, attempt!.id);
      attempt = attempt!.copyWith(answers: questionSet.attempt.answers);
      state = state.copyWith(
        activeAttempt: attempt,
        attemptQuestions: questionSet.questions,
        clearResult: true,
      );
    });
    return attempt;
  }

  Future<void> loadAttempt(String attemptId) async {
    final token = state.accessToken;
    if (token == null) return;
    await _run(() async {
      final questionSet = await _api.attemptQuestions(token, attemptId);
      state = state.copyWith(
        activeAttempt: questionSet.attempt,
        attemptQuestions: questionSet.questions,
      );
    });
  }

  Future<void> answerQuestion(String attemptId, String questionId, int optionIndex) async {
    final token = state.accessToken;
    final attempt = state.activeAttempt;
    if (token == null || attempt == null) return;
    final updatedAnswers = {...attempt.answers, questionId: optionIndex};
    state = state.copyWith(activeAttempt: attempt.copyWith(answers: updatedAnswers));
    try {
      await _api.saveAnswer(token, attemptId, questionId, optionIndex);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<AttemptResultData?> submitAttempt(String attemptId) async {
    final token = state.accessToken;
    if (token == null) return null;
    AttemptResultData? result;
    await _run(() async {
      result = await _api.submitAttempt(token, attemptId);
      state = state.copyWith(latestResult: result, activeAttempt: result!.attempt);
      await loadDashboardData();
    });
    return result;
  }

  Future<AttemptResultData?> loadResult(String attemptId) async {
    final token = state.accessToken;
    if (token == null) return null;
    AttemptResultData? result;
    await _run(() async {
      result = await _api.attemptResult(token, attemptId);
      state = state.copyWith(latestResult: result, activeAttempt: result!.attempt);
    });
    return result;
  }

  Future<void> updateCurrentUserProfile({
    required String name,
    required String username,
    required String bio,
    required String? profileImagePath,
    required String headline,
  }) async {
    final token = state.accessToken;
    if (token == null) return;
    await _run(() async {
      String? uploadedUrl = state.currentUser?.profileImagePath;
      if (profileImagePath != null && !profileImagePath.startsWith('http')) {
        uploadedUrl = await _api.uploadProfileImage(token, profileImagePath);
      } else if (profileImagePath == null) {
        uploadedUrl = null;
      }

      final updatedProfile = await _api.updateProfile(
        token,
        name: name,
        username: username,
        bio: bio,
        headline: headline,
        profileImageUrl: uploadedUrl,
      );
      final current = state.currentUser;
      if (current != null) {
        state = state.copyWith(
          currentUser: current.copyWith(
            name: updatedProfile.name,
            username: updatedProfile.username,
            bio: updatedProfile.bio,
            headline: updatedProfile.headline,
            profileImagePath: updatedProfile.profileImagePath,
            clearProfileImagePath: updatedProfile.profileImagePath == null,
          ),
          displayName: updatedProfile.name,
        );
      }
    });
  }

  Exam examById(String id) => state.exams.firstWhere((exam) => exam.id == id);
  ExamAttempt attemptById(String id) {
    if (state.activeAttempt?.id == id) return state.activeAttempt!;
    if (state.latestResult?.attempt.id == id) return state.latestResult!.attempt;
    throw StateError('Attempt not loaded');
  }

  ExamAttempt? latestCompletedAttemptForExam(String examId) {
    final result = state.latestResult;
    if (result != null && result.attempt.examId == examId) return result.attempt;
    return null;
  }

  AttemptSummary summaryForAttempt(String attemptId) => state.latestResult!.summary;

  AttemptSummary summaryForExamAttempt(ExamAttempt attempt) {
    final history = state.examHistories[attempt.examId] ?? const [];
    for (final item in history) {
      final match = item.attempts.where((entry) => entry.id == attempt.id);
      if (match.isNotEmpty) {
        final current = match.first;
        if (current.id == item.latestAttempt.id) {
          return item.latestSummary;
        }
      }
    }
    return const AttemptSummary(correctCount: 0, wrongCount: 0, unansweredCount: 0, negativeDeduction: 0, finalScore: 0);
  }

  List<Exam> visibleExamsForCurrentUser() => state.exams;
  bool isCompleted(String examId) => latestCompletedAttemptForExam(examId) != null;
  List<ExamineeAttemptHistory> attemptHistoryForExam(String examId) => state.examHistories[examId] ?? const [];

  Future<T?> _run<T>(Future<T> Function() action) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final result = await action();
      state = state.copyWith(isLoading: false, clearError: true);
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return null;
    }
  }

  String _composeRawFromDrafts(List<ParsedQuestionDraft> drafts) {
    final buffer = StringBuffer();
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      if (i > 0) buffer.writeln();
      buffer.writeln('${i + 1}. ${draft.prompt}');
      for (var j = 0; j < draft.options.length; j++) {
        buffer.writeln('${'ABCD'[j]}. ${draft.options[j]}');
      }
      buffer.writeln('Answer: ${'ABCD'[draft.correctIndex]}');
    }
    return buffer.toString().trim();
  }
}

enum UserRole { examiner, examinee }

enum AttemptStatus { inProgress, submitted, autoSubmitted, completed }

enum FriendRequestStatus { pending, accepted }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.bio,
    required this.profileImagePath,
    required this.headline,
    required this.role,
  });

  final String id;
  final String name;
  final String username;
  final String bio;
  final String? profileImagePath;
  final String headline;
  final UserRole role;

  AppUser copyWith({
    String? name,
    String? username,
    String? bio,
    String? profileImagePath,
    String? headline,
    bool clearProfileImagePath = false,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profileImagePath: clearProfileImagePath ? null : (profileImagePath ?? this.profileImagePath),
      headline: headline ?? this.headline,
      role: role,
    );
  }
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.sender,
    this.receiver,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final AppUser? sender;
  final AppUser? receiver;

  FriendRequest copyWith({FriendRequestStatus? status, AppUser? sender, AppUser? receiver}) {
    return FriendRequest(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      status: status ?? this.status,
      createdAt: createdAt,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
    );
  }
}

class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class Exam {
  const Exam({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.negativeMarkPerWrong,
    required this.createdBy,
    required this.isPublished,
    required this.questions,
    required this.highlight,
    required this.assignedExamineeIds,
  });

  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final double negativeMarkPerWrong;
  final String createdBy;
  final bool isPublished;
  final List<ExamQuestion> questions;
  final List<int> highlight;
  final List<String> assignedExamineeIds;

  Exam copyWith({bool? isPublished, List<ExamQuestion>? questions, List<String>? assignedExamineeIds}) {
    return Exam(
      id: id,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      negativeMarkPerWrong: negativeMarkPerWrong,
      createdBy: createdBy,
      isPublished: isPublished ?? this.isPublished,
      questions: questions ?? this.questions,
      highlight: highlight,
      assignedExamineeIds: assignedExamineeIds ?? this.assignedExamineeIds,
    );
  }
}

class ExamAttempt {
  const ExamAttempt({
    required this.id,
    required this.examId,
    required this.examineeId,
    required this.examineeName,
    required this.startedAt,
    required this.endAt,
    required this.answers,
    required this.status,
  });

  final String id;
  final String examId;
  final String examineeId;
  final String examineeName;
  final DateTime startedAt;
  final DateTime endAt;
  final Map<String, int> answers;
  final AttemptStatus status;

  ExamAttempt copyWith({Map<String, int>? answers, AttemptStatus? status}) {
    return ExamAttempt(
      id: id,
      examId: examId,
      examineeId: examineeId,
      examineeName: examineeName,
      startedAt: startedAt,
      endAt: endAt,
      answers: answers ?? this.answers,
      status: status ?? this.status,
    );
  }
}

class AttemptSummary {
  const AttemptSummary({
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.negativeDeduction,
    required this.finalScore,
  });

  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final double negativeDeduction;
  final double finalScore;
}

class ExamineeAttemptHistory {
  const ExamineeAttemptHistory({
    required this.examineeName,
    required this.attempts,
    required this.latestAttempt,
    required this.latestSummary,
    required this.bestScore,
  });

  final String examineeName;
  final List<ExamAttempt> attempts;
  final ExamAttempt latestAttempt;
  final AttemptSummary latestSummary;
  final double bestScore;
}

class ParsedQuestionDraft {
  const ParsedQuestionDraft({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
}

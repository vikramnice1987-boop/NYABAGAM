enum AppErrorCode {
  validationError,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  networkOffline,
  aiUnavailable,
  aiInvalidOutput,
  actionExecutionFailed,
  unknown,
}

class AppError implements Exception {
  const AppError({
    required this.code,
    required this.message,
    required this.userMessage,
    this.retryable = false,
    this.metadata = const {},
  });

  final AppErrorCode code;
  final String message;
  final String userMessage;
  final bool retryable;
  final Map<String, dynamic> metadata;

  factory AppError.offline() => const AppError(
    code: AppErrorCode.networkOffline,
    message: 'Device has no network connectivity.',
    userMessage: 'You are currently offline. Actions will be queued or retried once reconnected.',
    retryable: true,
  );

  factory AppError.aiUnavailable([String? details]) => AppError(
    code: AppErrorCode.aiUnavailable,
    message: details ?? 'AI service unreachable.',
    userMessage: 'The AI assistant is temporarily unavailable. Your input is safe and can be saved directly.',
    retryable: true,
  );

  factory AppError.unauthorized() => const AppError(
    code: AppErrorCode.unauthorized,
    message: 'User session invalid or expired.',
    userMessage: 'Please sign in to access your secure personal memories.',
    retryable: false,
  );

  @override
  String toString() => 'AppError($code: $message)';
}
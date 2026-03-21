/// Chronicle — Centralized Exception Types
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.originalError});
}

/// Base class for all failures in the application
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

/// Failure when server communication fails
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

/// Failure when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

/// General failure for unexpected errors
class GeneralFailure extends Failure {
  const GeneralFailure([super.message = 'An unexpected error occurred']);
}
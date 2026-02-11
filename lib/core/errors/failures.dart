/// Base class for all failures in the application
abstract class Failure {
  final String message;
  
  const Failure(this.message);
  
  @override
  String toString() => message;
}

/// Failure when server communication fails
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

/// Failure when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

/// General failure for unexpected errors
class GeneralFailure extends Failure {
  const GeneralFailure([String message = 'An unexpected error occurred']) : super(message);
}

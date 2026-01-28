abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

/// Failure pour les erreurs 403 (compte non approuvé, suspendu, etc.)
class ForbiddenFailure extends Failure {
  final String? errorCode;
  
  const ForbiddenFailure(super.message, {this.errorCode});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> errors;

  ValidationFailure(this.errors)
      : super(errors.values.expand((element) => element).join('\n'));
}

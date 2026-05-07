class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException({required this.message});
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException({required this.message});
}

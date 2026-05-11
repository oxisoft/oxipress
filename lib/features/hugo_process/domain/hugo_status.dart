/// Lifecycle status of the Hugo serve subprocess.
sealed class HugoStatus {
  const HugoStatus();
}

final class HugoStopped extends HugoStatus {
  const HugoStopped();
}

final class HugoStarting extends HugoStatus {
  const HugoStarting({required this.projectPath, required this.port});

  final String projectPath;
  final int port;
}

final class HugoRunning extends HugoStatus {
  const HugoRunning({required this.projectPath, required this.port});

  final String projectPath;
  final int port;

  String get baseUrl => 'http://127.0.0.1:$port';
}

final class HugoErrored extends HugoStatus {
  const HugoErrored({required this.message, this.exitCode});

  final String message;
  final int? exitCode;
}

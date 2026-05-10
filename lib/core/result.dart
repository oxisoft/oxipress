/// Result type used at fallible boundaries instead of throwing.
///
/// Prefer this over exceptions for any operation a caller is expected to
/// handle (parsing, IO, child-process exit codes). Exceptions remain reserved
/// for programmer errors.
sealed class Result<T, E> {
  const Result();

  const factory Result.success(T value) = Success<T, E>;
  const factory Result.failure(E error) = Failure<T, E>;

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get valueOrNull => switch (this) {
        Success<T, E>(:final value) => value,
        Failure<T, E>() => null,
      };

  E? get errorOrNull => switch (this) {
        Success<T, E>() => null,
        Failure<T, E>(:final error) => error,
      };

  R fold<R>(R Function(T value) onSuccess, R Function(E error) onFailure) =>
      switch (this) {
        Success<T, E>(:final value) => onSuccess(value),
        Failure<T, E>(:final error) => onFailure(error),
      };

  Result<U, E> map<U>(U Function(T value) f) => switch (this) {
        Success<T, E>(:final value) => Result<U, E>.success(f(value)),
        Failure<T, E>(:final error) => Result<U, E>.failure(error),
      };

  Result<T, F> mapError<F>(F Function(E error) f) => switch (this) {
        Success<T, E>(:final value) => Result<T, F>.success(value),
        Failure<T, E>(:final error) => Result<T, F>.failure(f(error)),
      };

  Result<U, E> flatMap<U>(Result<U, E> Function(T value) f) => switch (this) {
        Success<T, E>(:final value) => f(value),
        Failure<T, E>(:final error) => Result<U, E>.failure(error),
      };
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Success<T, E> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);

  final E error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T, E> && other.error == error);

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

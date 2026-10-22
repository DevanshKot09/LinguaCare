sealed class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure([super.message = 'Network connection error. Please try again.']);
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([super.message = 'Invalid email or password.']);
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([super.message = 'An account already exists with this email.']);
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([super.message = 'Password is too weak. Please use at least 8 characters with letters and numbers.']);
}

class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure([super.message = 'This user account has been disabled.']);
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure([super.message = 'Too many requests. Please try again later.']);
}

class OtpCooldownFailure extends AuthFailure {
  const OtpCooldownFailure([super.message = 'Please wait 60 seconds before requesting another code.']);
}

class OtpRateLimitFailure extends AuthFailure {
  const OtpRateLimitFailure([super.message = 'Maximum OTP requests reached. Please try again later.']);
}

class InvalidOtpFailure extends AuthFailure {
  const InvalidOtpFailure([super.message = 'Invalid or expired verification code.']);
}

class MaxOtpAttemptsFailure extends AuthFailure {
  const MaxOtpAttemptsFailure([super.message = 'Maximum verification attempts exceeded. Please request a new code.']);
}

class UnexpectedAuthFailure extends AuthFailure {
  const UnexpectedAuthFailure([super.message = 'An unexpected error occurred. Please try again.']);
}

class CancelledAuthFailure extends AuthFailure {
  const CancelledAuthFailure([super.message = 'Sign-in cancelled.']);
}

import "package:oss_surveys_api/oss_surveys_api.dart";

/// Exception thrown when an error occurs while submitting a survey answer
///
/// This exception is used to distinguish Sentry reports between exceptions thrown while submitting a survey answer
class SurveyAnswerException implements Exception {
  final dynamic exception;
  final DevicePageSurveyAnswer answer;

  const SurveyAnswerException(this.exception, {required this.answer});

  @override
  String toString() {
    return "SurveyAnswerException: $exception, Answer: $answer";
  }
}

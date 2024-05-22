import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
import "package:oss_surveys_customer/utils/exception/survey_answer_exception.dart";
import "package:simple_logger/simple_logger.dart";
import "../database/dao/answer_dao.dart";
import "../database/dao/keys_dao.dart";
import "../main.dart";

/// Answer controller class
///
/// Provides utility for submitting answers to the backend
class AnswerController {
  /// Submits [answer] to the backend
  ///
  /// If it fails, it persists the answer to the local database for later submission
  static void submitAnswer(
    String answer,
    database.Page page,
    String deviceSurveyId,
  ) async {
    final builtAnswer = surveys_api.DevicePageSurveyAnswer((builder) {
      builder.pageId = page.externalId;
      builder.answer = answer;
    });
    try {
      surveys_api.DeviceDataApi deviceDataApi =
          await apiFactory.getDeviceDataApi();
      String? deviceId = await keysDao.getDeviceId();
      if (deviceId == null) throw Exception("Device ID not found!");

      SimpleLogger().info("Created answer:");
      SimpleLogger().info("Device ID: $deviceId");
      SimpleLogger().info("Device Survey ID: $deviceSurveyId");
      SimpleLogger().info("Page ID: ${page.externalId}");
      SimpleLogger().info("Answer: $answer");

      await deviceDataApi.submitSurveyAnswer(
        deviceId: deviceId,
        deviceSurveyId: deviceSurveyId,
        pageId: page.externalId,
        devicePageSurveyAnswer: builtAnswer,
      );
      SimpleLogger().info("Answer submitted successfully!");
    } catch (exception, stackTrace) {
      SimpleLogger().shout(
        "Error while answering ${page.questionType} question, persisting for later...: $exception",
      );
      await _persistFailedAnswer(
          builtAnswer,
          database.AnswersCompanion.insert(
            pageExternalId: page.externalId,
            questionType: page.questionType!,
            answer: answer,
            timestamp: Value(DateTime.now()),
          ));
      await reportError(
        SurveyAnswerException(exception, answer: builtAnswer),
        stackTrace,
      );
    }
  }

  static Future<void> _persistFailedAnswer(
    surveys_api.DevicePageSurveyAnswer builtAnswer,
    database.AnswersCompanion answer,
  ) async {
    try {
      await answersDao.createAnswer(answer);
    } catch (exception, stackTrace) {
      SimpleLogger().shout("Error while persisting failed answer: $exception");
      await reportError(
        SurveyAnswerException(exception, answer: builtAnswer),
        stackTrace,
      );
    }
  }
}

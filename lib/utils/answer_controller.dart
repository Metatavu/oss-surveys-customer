import "package:oss_surveys_customer/database/database.dart" as database;
import "package:oss_surveys_api/oss_surveys_api.dart" as surveys_api;
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
    try {
      surveys_api.DeviceDataApi deviceDataApi =
          await apiFactory.getDeviceDataApi();
      String? deviceId = await keysDao.getDeviceId();
      if (deviceId == null) throw Exception("Device ID not found!");
      surveys_api.DevicePageSurveyAnswerBuilder builder =
          surveys_api.DevicePageSurveyAnswerBuilder();
      builder.pageId = page.externalId;
      builder.answer = answer;

      await deviceDataApi.submitSurveyAnswer(
        deviceId: deviceId,
        deviceSurveyId: deviceSurveyId,
        pageId: page.externalId,
        devicePageSurveyAnswer: builder.build(),
      );
    } catch (error) {
      logger.shout(
        "Error while answering single select question, persisting for later...: $error",
      );
      await answersDao.createAnswer(
        database.AnswersCompanion.insert(
          pageId: page.id,
          pageExternalId: page.externalId,
          questionType: page.questionType!,
          answer: answer,
        ),
      );
    }
  }
}

import "dart:async";
import "dart:io";
import "dart:isolate";
import "package:drift/drift.dart";
import "package:drift/isolate.dart";
import "package:drift/native.dart";
import "package:flutter/services.dart";
import "package:oss_surveys_api/oss_surveys_api.dart";
import "package:oss_surveys_customer/api/api_factory.dart";
import "package:oss_surveys_customer/database/dao/answer_dao.dart";
import "package:oss_surveys_customer/database/dao/keys_dao.dart";
import "package:oss_surveys_customer/database/database.dart";
import "package:oss_surveys_customer/main.dart";
import "package:oss_surveys_customer/utils/exception/survey_answer_exception.dart";
import "package:path_provider/path_provider.dart";
import "package:simple_logger/simple_logger.dart";
import "package:path/path.dart" as p;

/// Arguments passed to the isolate
///
/// Isolates can only be passed one argument when spawned so we need to wrap them within a class.
class BackgroundServiceArgs {
  final String apiBasePath;
  final SendPort sendPort;
  final DriftIsolate driftIsolate;

  BackgroundServiceArgs(this.apiBasePath, this.sendPort, this.driftIsolate);
}

/// This background service periodically checks for unsent answers and attepmts to send them to the backend
class BackgroundService {
  static Future<DriftIsolate?> get _isolate async {
    final token = RootIsolateToken.instance;
    if (token == null) {
      SimpleLogger().warning("RootIsolateToken is null.");
      return null;
    }
    return await DriftIsolate.spawn(() {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);

      return LazyDatabase(() async {
        final dbFolder = await getApplicationDocumentsDirectory();
        final file = File(p.join(dbFolder.path, "db.sqlite"));

        return NativeDatabase(file);
      });
    });
  }

  /// Callback for messages sent from the isolate
  ///
  /// This is used to catch [SurveyAnswerException]s and report them with Sentry
  static Future<void> _onIsolateSurveyAnswerException(dynamic message) async {
    if (message is SurveyAnswerException) {
      await reportError(message, null);
    }
  }

  /// Starts the background service
  static Future<void> start(String apiBasePath) async {
    SimpleLogger().info("Starting background service...");
    final receivePort = ReceivePort();

    receivePort.listen(_onIsolateSurveyAnswerException);
    DriftIsolate? driftIsolate = await _isolate;
    if (driftIsolate == null) {
      SimpleLogger()
          .warning("DriftIsolate is null. Aborting background service.");
      return;
    }
    Isolate.spawn(
      _startIsolate,
      BackgroundServiceArgs(apiBasePath, receivePort.sendPort, driftIsolate),
    );
  }

  /// The entry point for the isolate
  ///
  /// It opens a background connection to the database and every 30 minutes checks for unsent answers in batches of 10.
  /// If unsent answers are found, it attempts to send them to the backend.
  /// If it success, it deletes the answer from the local database.
  /// If it fails, it sends the exception back to the main isolate.
  static Future<void> _startIsolate(BackgroundServiceArgs args) async {
    final conn = await args.driftIsolate.connect();
    final db = Database.fromQueryExecutor(conn);
    final answerDao = AnswersDao(db);
    final keysDao = KeysDao(db);
    Timer.periodic(const Duration(minutes: 30), (_) async {
      SimpleLogger().info("Checking for unsent answers");
      final unsentAnswers = await answerDao.listAnswers(limit: 10);
      final deviceKey = await keysDao.getDeviceKey();
      final deviceId = await keysDao.getDeviceId();
      final api = await ApiFactory().getDeviceDataApi(
          overrideApiBasePath: args.apiBasePath, overrideDeviceKey: deviceKey);
      if (deviceId == null) {
        SimpleLogger().warning("Device ID is null.");
        return;
      }

      SimpleLogger().info("Unsent answers: ${unsentAnswers.length}");
      for (final answer in unsentAnswers) {
        try {
          SimpleLogger().info("Attempting to send unsent answer: $answer");
          final builtAnswer = DevicePageSurveyAnswer((builder) {
            builder.pageId = answer.pageExternalId;
            builder.answer = answer.answer;
            builder.deviceAnswerId = answer.id;
          });

          await api.submitSurveyAnswerV2(
            deviceId: deviceId,
            devicePageSurveyAnswer: builtAnswer,
          );
          SimpleLogger().info("Successfully sent unsent answer!");
          await answerDao.deleteAnswer(answer.id);
          SimpleLogger().info("Deleted unsent answer from local database");
        } catch (exception) {
          SimpleLogger().shout(
            "Error while sending unsent answer: ${exception.toString()}",
          );
          args.sendPort.send(exception);
        }
      }
    });
  }
}

import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/database.dart";
import "../model/answer.dart";

part "answer_dao.g.dart";

/// Answers DAO
@DriftAccessor(tables: [Answers], include: {"tables.drift"})
class AnswersDao extends DatabaseAccessor<Database> with _$AnswersDaoMixin {
  AnswersDao(Database database) : super(database);

  /// Gets one answer
  Future<Answer?> getAnswer() async {
    return await (select(answers)..limit(1)).getSingleOrNull();
  }

  /// Creates a new answer
  Future<int> createAnswer(AnswersCompanion newAnswer) async {
    return await into(answers).insert(newAnswer);
  }
}

final answersDao = AnswersDao(database);

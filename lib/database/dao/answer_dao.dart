import "package:drift/drift.dart";
import "package:oss_surveys_customer/database/database.dart";
import "../model/answer.dart";

part "answer_dao.g.dart";

/// Answers DAO
@DriftAccessor(tables: [Answers])
class AnswersDao extends DatabaseAccessor<Database> with _$AnswersDaoMixin {
  AnswersDao(Database database) : super(database);

  /// Gets one answer
  Future<Answer?> getAnswer() async {
    return await (select(answers)..limit(1)).getSingleOrNull();
  }

  /// Creates a new answer
  Future<Answer> createAnswer(AnswersCompanion newAnswer) async {
    int createdAnswerId = await into(answers).insert(newAnswer);

    return await (select(answers)
          ..where((row) => row.id.equals(createdAnswerId)))
        .getSingle();
  }

  /// Deletes an answer by [id]
  Future<int> deleteAnswer(int id) async {
    return await (delete(answers)..where((answer) => answer.id.equals(id)))
        .go();
  }

  /// Lists all answers
  Future<List<Answer>> listAnswers({int? limit}) async {
    if (limit == null) return await select(answers).get();
    return await (select(answers)..limit(limit)).get();
  }
}

final answersDao = AnswersDao(database);

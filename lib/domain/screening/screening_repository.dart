import 'instrument.dart';
import 'screening_result.dart';

abstract class ScreeningRepository {
  Future<Instrument> loadInstrument(String instrumentId);
  Future<void> saveScreeningResult(ScreeningResult result);
  Future<List<ScreeningResult>> getScreeningHistoryForChild(String childId);
  Future<List<ScreeningResult>> getScreeningHistoryForSelf(String subjectUid);
  Future<void> deleteScreeningResult(String sessionId);

  // Local draft pause/resume persistence
  Future<void> saveDraftAnswers(String instrumentId, Map<String, int?> answers);
  Future<Map<String, int?>> loadDraftAnswers(String instrumentId);
  Future<void> clearDraftAnswers(String instrumentId);
}

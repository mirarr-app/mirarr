import 'package:flutter_test/flutter_test.dart';
import 'package:Mirarr/functions/get_imdb_score.dart';

void main() {
  group('IMDb API Helper Function Tests', () {
    const String fightClubId = 'tt0137523';
    const String batmanId = 'tt0096895';
    const String nonExistentId = 'tt9999999';

    test('getImdbScore - single mode returns correct score for valid ID', () async {
      final score = await getImdbScore(fightClubId, useBatch: false);
      expect(score, isNotNull);
      expect(score, greaterThanOrEqualTo(8.0)); // Fight Club rating is typically 8.8
    });

    test('getImdbScore - single mode returns null for non-existent ID', () async {
      final score = await getImdbScore(nonExistentId, useBatch: false);
      expect(score, isNull);
    });

    test('getImdbScore - batch mode returns correct score for valid ID', () async {
      final score = await getImdbScore(fightClubId, useBatch: true);
      expect(score, isNotNull);
      expect(score, greaterThanOrEqualTo(8.0));
    });

    test('getImdbScore - batch mode returns null for non-existent ID', () async {
      final score = await getImdbScore(nonExistentId, useBatch: true);
      expect(score, isNull);
    });

    test('getImdbScoresBatch - batch mode returns correct map of scores', () async {
      final scores = await getImdbScoresBatch([fightClubId, batmanId]);
      expect(scores, isNotEmpty);
      expect(scores.containsKey(fightClubId), isTrue);
      expect(scores.containsKey(batmanId), isTrue);
      expect(scores[fightClubId], greaterThanOrEqualTo(8.0));
      expect(scores[batmanId], greaterThanOrEqualTo(7.0));
    });

    test('getImdbScoresBatch - handles empty list gracefully', () async {
      final scores = await getImdbScoresBatch([]);
      expect(scores, isEmpty);
    });

    test('getImdbScoresBatch - handles non-existent IDs in the list', () async {
      final scores = await getImdbScoresBatch([fightClubId, nonExistentId]);
      expect(scores.containsKey(fightClubId), isTrue);
      expect(scores.containsKey(nonExistentId), isFalse);
    });
  });
}

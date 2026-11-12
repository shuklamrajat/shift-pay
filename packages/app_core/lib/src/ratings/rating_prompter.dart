import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings.dart';

/// Asks the OS for the native review sheet. The OS decides whether it shows.
abstract class ReviewRequester {
  Future<void> request();
}

class StoreReviewRequester implements ReviewRequester {
  @override
  Future<void> request() async {
    final r = InAppReview.instance;
    if (await r.isAvailable()) await r.requestReview();
  }
}

/// When to ask for a rating. Only after the person finished something
/// (a shift logged, a fill-up saved, an export made), never on launch.
///
/// Rules: not in the first [minDaysInstalled] days; first ask after
/// [firstAfterTasks] completed tasks; at least [minDaysBetween] days between
/// asks; at most [maxPerYear] asks in any rolling 365 days (Apple's cap is 3).
class RatingPolicy {
  const RatingPolicy({
    this.firstAfterTasks = 5,
    this.minDaysInstalled = 2,
    this.minDaysBetween = 60,
    this.maxPerYear = 3,
  });
  final int firstAfterTasks;
  final int minDaysInstalled;
  final int minDaysBetween;
  final int maxPerYear;

  bool shouldAsk({
    required DateTime now,
    required DateTime installedAt,
    required int completedTasks,
    required List<DateTime> previousAsks,
  }) {
    if (now.difference(installedAt).inDays < minDaysInstalled) return false;
    if (completedTasks < firstAfterTasks) return false;
    if (previousAsks.isNotEmpty) {
      final last = previousAsks.reduce((a, b) => a.isAfter(b) ? a : b);
      if (now.difference(last).inDays < minDaysBetween) return false;
    }
    final inYear = previousAsks.where((d) => now.difference(d).inDays < 365).length;
    return inYear < maxPerYear;
  }
}

final reviewRequesterProvider = Provider<ReviewRequester>((ref) => StoreReviewRequester());
final ratingPolicyProvider = Provider<RatingPolicy>((ref) => const RatingPolicy());

class RatingPrompter {
  RatingPrompter(this._prefs, this._requester, this._policy, this._clock, this._installedAt);

  static const _kTasks = 'core.rating.completedTasks';
  static const _kAsks = 'core.rating.asks';

  final SharedPreferences _prefs;
  final ReviewRequester _requester;
  final RatingPolicy _policy;
  final DateTime Function() _clock;
  final DateTime _installedAt;

  int get completedTasks => _prefs.getInt(_kTasks) ?? 0;

  List<DateTime> get asks =>
      (_prefs.getStringList(_kAsks) ?? const []).map((s) => DateTime.fromMillisecondsSinceEpoch(int.parse(s))).toList();

  /// Call once each time the person completes a meaningful task.
  /// Returns true when the review sheet was requested.
  Future<bool> recordCompletedTask() async {
    final tasks = completedTasks + 1;
    await _prefs.setInt(_kTasks, tasks);
    final now = _clock();
    final previous = asks;
    if (!_policy.shouldAsk(now: now, installedAt: _installedAt, completedTasks: tasks, previousAsks: previous)) {
      return false;
    }
    await _prefs.setStringList(_kAsks, [
      ...previous.map((d) => '${d.millisecondsSinceEpoch}'),
      '${now.millisecondsSinceEpoch}',
    ]);
    await _requester.request();
    return true;
  }
}

final ratingPrompterProvider = Provider<RatingPrompter>(
  (ref) => RatingPrompter(
    ref.watch(sharedPrefsProvider),
    ref.watch(reviewRequesterProvider),
    ref.watch(ratingPolicyProvider),
    ref.watch(clockProvider),
    ref.read(coreSettingsProvider).firstOpenedAt,
  ),
);

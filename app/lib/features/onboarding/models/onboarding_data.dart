import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingData {
  final String? wantsToLearn;
  final String? heardFrom;
  final String? tradition;
  final List<String> motivation;
  final String? bibleLevel;
  final int dailyGoalMinutes;
  final bool isExperienced;

  const OnboardingData({
    this.wantsToLearn,
    this.heardFrom,
    this.tradition,
    this.motivation = const [],
    this.bibleLevel,
    this.dailyGoalMinutes = 10,
    this.isExperienced = false,
  });

  OnboardingData copyWith({
    String? wantsToLearn,
    String? heardFrom,
    String? tradition,
    List<String>? motivation,
    String? bibleLevel,
    int? dailyGoalMinutes,
    bool? isExperienced,
  }) {
    return OnboardingData(
      wantsToLearn: wantsToLearn ?? this.wantsToLearn,
      heardFrom: heardFrom ?? this.heardFrom,
      tradition: tradition ?? this.tradition,
      motivation: motivation ?? this.motivation,
      bibleLevel: bibleLevel ?? this.bibleLevel,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      isExperienced: isExperienced ?? this.isExperienced,
    );
  }

  /// Alias used by legacy screens (denomination_screen / daily_goal_screen).
  String? get denomination => tradition;
}

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(const OnboardingData());

  void setWantsToLearn(String v) => state = state.copyWith(wantsToLearn: v);
  void setHeardFrom(String v) => state = state.copyWith(heardFrom: v);
  void setTradition(String v) => state = state.copyWith(tradition: v);
  void setMotivation(List<String> v) => state = state.copyWith(motivation: v);
  void setBibleLevel(String v) => state = state.copyWith(bibleLevel: v);
  void setDailyGoal(int m) => state = state.copyWith(dailyGoalMinutes: m);
  void setExperienced(bool e) => state = state.copyWith(isExperienced: e);

  /// Legacy alias used by denomination_screen.
  void setDenomination(String? d) {
    if (d != null) state = state.copyWith(tradition: d);
  }
}

final onboardingDataProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier();
});

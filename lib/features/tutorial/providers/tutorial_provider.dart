import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/secure_storage/secure_storage_service.dart';

// List of all tutorial steps in chronological order
const List<String> kTutorialSteps = [
  'dashboard_hello',
  'dashboard_hero',
  'dashboard_action_needed',
  'bottom_nav_household',
  'bottom_nav_subscriptions',
  'bottom_nav_account',
];

class TutorialState {
  final Map<String, bool> completedSteps;
  final String? activeStep;

  TutorialState({
    required this.completedSteps,
    this.activeStep,
  });

  TutorialState copyWith({
    Map<String, bool>? completedSteps,
    String? activeStep,
    bool clearActiveStep = false,
  }) {
    return TutorialState(
      completedSteps: completedSteps ?? this.completedSteps,
      activeStep: clearActiveStep ? null : (activeStep ?? this.activeStep),
    );
  }
}

class TutorialNotifier extends AsyncNotifier<TutorialState> {
  late final SecureStorageService _storage;

  @override
  Future<TutorialState> build() async {
    _storage = ref.watch(secureStorageServiceProvider);
    
    final completed = <String, bool>{};
    for (final step in kTutorialSteps) {
      completed[step] = await _storage.isTutorialCompleted(step);
    }

    final active = kTutorialSteps.firstWhere(
      (step) => completed[step] != true,
      orElse: () => '',
    );

    return TutorialState(
      completedSteps: completed,
      activeStep: active.isEmpty ? null : active,
    );
  }

  Future<void> completeStep(String stepId) async {
    final currentState = state.value;
    if (currentState == null) return;

    await _storage.saveTutorialCompleted(stepId, true);
    
    final newCompleted = Map<String, bool>.from(currentState.completedSteps);
    newCompleted[stepId] = true;

    final nextActive = kTutorialSteps.firstWhere(
      (step) => newCompleted[step] != true,
      orElse: () => '',
    );

    state = AsyncValue.data(TutorialState(
      completedSteps: newCompleted,
      activeStep: nextActive.isEmpty ? null : nextActive,
    ));
  }

  Future<void> resetAll() async {
    for (final step in kTutorialSteps) {
      await _storage.deleteTutorialCompleted(step);
    }
    
    final newCompleted = {for (var step in kTutorialSteps) step: false};
    state = AsyncValue.data(TutorialState(
      completedSteps: newCompleted,
      activeStep: kTutorialSteps.first,
    ));
  }
  
  Future<void> skipAll() async {
    for (final step in kTutorialSteps) {
      await _storage.saveTutorialCompleted(step, true);
    }
    
    final newCompleted = {for (var step in kTutorialSteps) step: true};
    state = AsyncValue.data(TutorialState(
      completedSteps: newCompleted,
      activeStep: null,
    ));
  }
}

final tutorialProvider = AsyncNotifierProvider<TutorialNotifier, TutorialState>(
  TutorialNotifier.new,
);

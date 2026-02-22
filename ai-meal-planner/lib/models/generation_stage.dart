enum GenerationStage {
  idle,
  validatingInput,
  checkingCache,
  requestingAi,
  generatingLocal,
  enrichingRecipes,
  savingHistory,
  completed,
  failed,
}

class GenerationProgress {
  const GenerationProgress({
    required this.stage,
    required this.message,
    required this.percent,
  });

  final GenerationStage stage;
  final String message;
  final double percent;
}

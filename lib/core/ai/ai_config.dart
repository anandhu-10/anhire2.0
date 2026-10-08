enum AiTask {
  resumeAnalysis,
  codingHint,
  aptitudeAnswer,
  interviewQuestionGen,
  interviewAnswerEval,
  learningRoadmap,
  adminBatchAptitude,
}

class AiTaskConfig {
  final double temperature;
  final int maxOutputTokens;
  final String responseMimeType;

  const AiTaskConfig({
    required this.temperature,
    required this.maxOutputTokens,
    this.responseMimeType = 'application/json',
  });
}

class AiConfig {
  static const Map<AiTask, AiTaskConfig> taskConfigs = {
    AiTask.resumeAnalysis: AiTaskConfig(
      temperature: 0.2,
      maxOutputTokens: 2048,
    ),
    AiTask.codingHint: AiTaskConfig(
      temperature: 0.5,
      maxOutputTokens: 512,
    ),
    AiTask.aptitudeAnswer: AiTaskConfig(
      temperature: 0.2,
      maxOutputTokens: 1024,
    ),
    AiTask.interviewQuestionGen: AiTaskConfig(
      temperature: 0.7,
      maxOutputTokens: 2048,
    ),
    AiTask.interviewAnswerEval: AiTaskConfig(
      temperature: 0.2,
      maxOutputTokens: 1024,
    ),
    AiTask.learningRoadmap: AiTaskConfig(
      temperature: 0.7,
      maxOutputTokens: 3072,
    ),
    AiTask.adminBatchAptitude: AiTaskConfig(
      temperature: 0.2,
      maxOutputTokens: 4096,
    ),
  };

  static AiTaskConfig getConfig(AiTask task) {
    return taskConfigs[task] ??
        const AiTaskConfig(
          temperature: 0.2,
          maxOutputTokens: 2048,
        );
  }
}

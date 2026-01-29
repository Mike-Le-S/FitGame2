/// Data model for sleep metric information used in educational modals
class SleepMetricInfo {
  final String title;
  final String description;
  final List<String> benefits;
  final String fitnessImpact;
  final String idealRange;

  const SleepMetricInfo({
    required this.title,
    required this.description,
    required this.benefits,
    required this.fitnessImpact,
    required this.idealRange,
  });
}

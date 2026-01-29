/// Data model for heart metric information used in educational modals
class HeartMetricInfo {
  final String title;
  final String description;
  final List<String> benefits;
  final String fitnessImpact;
  final String idealRange;

  const HeartMetricInfo({
    required this.title,
    required this.description,
    required this.benefits,
    required this.fitnessImpact,
    required this.idealRange,
  });
}

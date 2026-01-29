/// Data model for heart rate historical chart data
class HeartHistoryData {
  final String day;
  final int restingHR;
  final int hrv;
  final int trend; // -1, 0, 1

  const HeartHistoryData({
    required this.day,
    required this.restingHR,
    required this.hrv,
    required this.trend,
  });
}

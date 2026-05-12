import 'rat.dart';

class RatRemoteSnapshot {
  const RatRemoteSnapshot({required this.rat, required this.serverUpdatedAt});

  final Rat rat;
  final DateTime serverUpdatedAt;
}

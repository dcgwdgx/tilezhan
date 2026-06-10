import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global animation speed factor.
/// 1.0 = full (beginner), 0.2 = fast (expert), 0.0 = off
final animationSpeedProvider = StateProvider<double>((ref) => 1.0);

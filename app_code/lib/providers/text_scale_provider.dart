import 'package:flutter_riverpod/flutter_riverpod.dart';

final textScaleProvider = NotifierProvider<TextScaleNotifier, double>(
  TextScaleNotifier.new,
);

class TextScaleNotifier extends Notifier<double> {
  @override
  double build() => 1.0;

  void setTextScale(double scale) {
    state = scale.clamp(0.8, 1.5).toDouble();
  }

  void resetTextScale() {
    state = 1.0;
  }
}

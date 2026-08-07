import 'package:flutter_test/flutter_test.dart';
import 'package:robot_compresor_video/core/services/ad_service.dart';

void main() {
  test('ads remain disabled in debug builds', () {
    expect(AdService.shouldLoadAds, isFalse);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spike_flutter_app/core/api_config.dart';
import 'package:spike_flutter_app/core/theme.dart';

void main() {
  test('production API configuration uses HTTPS', () {
    expect(ApiConfig.baseUrl.startsWith('https://'), isTrue);
    expect(ApiConfig.baseUrl, contains('/api/v1'));
    expect(ApiConfig.assetBaseUrl.startsWith('https://'), isTrue);
  });

  test('light and dark themes are configured', () {
    expect(spikeTheme.brightness, Brightness.light);
    expect(spikeDarkTheme.brightness, Brightness.dark);
    expect(spikeTheme.fontFamily, 'GraphikArabic');
    expect(spikeDarkTheme.fontFamily, 'GraphikArabic');
  });

  test('shared spacing and radius system stays valid', () {
    expect(SpikeSpacing.xs, greaterThan(0));
    expect(SpikeSpacing.page, greaterThan(SpikeSpacing.md));
    expect(SpikeRadius.control, greaterThan(0));
    expect(SpikeRadius.card, greaterThanOrEqualTo(SpikeRadius.control));
  });
}

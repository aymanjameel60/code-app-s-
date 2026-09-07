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
    expect(spikeTheme.scaffoldBackgroundColor, spikeBg);
    expect(spikeDarkTheme.scaffoldBackgroundColor, spikeDarkBg);
  });

  test('shared spacing and radius system matches reference values', () {
    expect(SpikeSpacing.page, 17);
    expect(SpikeSpacing.xxl, 32);
    expect(SpikeRadius.card, 16);
    expect(SpikeRadius.control, 25);
  });
}

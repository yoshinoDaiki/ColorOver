import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class BannerAdPlaceholder extends StatefulWidget {
  const BannerAdPlaceholder({super.key});

  @override
  State<BannerAdPlaceholder> createState() => _BannerAdPlaceholderState();
}

class _BannerAdPlaceholderState extends State<BannerAdPlaceholder> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  Orientation? _loadedOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBannerIfNeeded();
  }

  Future<void> _loadBannerIfNeeded() async {
    if (!mounted || _isLoading || !AdService.instance.isSupported) {
      return;
    }

    final currentOrientation = MediaQuery.orientationOf(context);
    if (_isLoaded && _loadedOrientation == currentOrientation && _bannerAd != null) {
      return;
    }

    _isLoading = true;
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;

    final horizontalMargin = 24;
    final availableWidth = math.max(
      1,
      MediaQuery.sizeOf(context).width.truncate() - horizontalMargin,
    );

    final adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      availableWidth,
    );

    if (!mounted) {
      _isLoading = false;
      return;
    }

    if (adSize == null) {
      _isLoading = false;
      return;
    }

    final adUnitId = AdService.instance.bannerAdUnitId;
    if (adUnitId == null) {
      _isLoading = false;
      return;
    }

    final banner = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _loadedOrientation = currentOrientation;
          });
          _isLoading = false;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          if (!mounted) {
            _isLoading = false;
            return;
          }
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
          _isLoading = false;
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildFallback({required String label}) {
    return Container(
      height: 60,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.instance.isSupported) {
      return _buildFallback(label: kIsWeb ? 'BANNER UNSUPPORTED ON WEB' : 'BANNER UNSUPPORTED');
    }

    final bannerAd = _bannerAd;
    if (!_isLoaded || bannerAd == null) {
      return _buildFallback(label: 'AD LOADING...');
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      alignment: Alignment.center,
      child: SizedBox(
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        child: AdWidget(ad: bannerAd),
      ),
    );
  }
}

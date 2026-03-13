import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const String androidAppId = 'ca-app-pub-3134818098587795~7741465311';
  static const String androidBannerAdUnitId = 'ca-app-pub-3134818098587795/9238379810';
  static const String androidRewardedAdUnitId = 'ca-app-pub-3134818098587795/8299722722';

  static const String iosAppId = 'ca-app-pub-3134818098587795~9054546985';
  static const String iosBannerAdUnitId = 'ca-app-pub-3134818098587795/3790941583';
  static const String iosRewardedAdUnitId = 'ca-app-pub-3134818098587795/1259671657';

  bool _isInitializing = false;
  bool _isInitialized = false;
  bool _isRewardedLoading = false;
  bool _isShowingRewarded = false;

  RewardedAd? _rewardedAd;

  bool get isSupported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get isShowingRewarded => _isShowingRewarded;

  String? get bannerAdUnitId {
    if (!isSupported) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidBannerAdUnitId;
      case TargetPlatform.iOS:
        return iosBannerAdUnitId;
      default:
        return null;
    }
  }

  String? get rewardedAdUnitId {
    if (!isSupported) return null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidRewardedAdUnitId;
      case TargetPlatform.iOS:
        return iosRewardedAdUnitId;
      default:
        return null;
    }
  }

  Future<void> initialize() async {
    if (!isSupported || _isInitialized || _isInitializing) {
      return;
    }

    _isInitializing = true;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _loadRewardedAd();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> preloadRewardedAd() async {
    await initialize();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    final adUnitId = rewardedAdUnitId;
    if (!_isInitialized ||
        _isRewardedLoading ||
        _rewardedAd != null ||
        adUnitId == null) {
      return;
    }

    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedLoading = false;
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required Future<void> Function() onFinished,
  }) async {
    await initialize();

    if (!isSupported || _isShowingRewarded) {
      await onFinished();
      return;
    }

    final ad = _rewardedAd;
    if (ad == null) {
      _loadRewardedAd();
      await onFinished();
      return;
    }

    _rewardedAd = null;
    _isShowingRewarded = true;
    var handled = false;

    Future<void> finish() async {
      if (handled) return;
      handled = true;
      _isShowingRewarded = false;
      _loadRewardedAd();
      await onFinished();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        await finish();
      },
      onAdFailedToShowFullScreenContent: (ad, error) async {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        await finish();
      },
    );

    try {
      ad.show(
        onUserEarnedReward: (ad, reward) {},
      );
    } catch (e) {
      debugPrint('Rewarded ad show exception: $e');
      ad.dispose();
      await finish();
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}

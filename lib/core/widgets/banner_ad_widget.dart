import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:robot_compresor_video/core/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  int? _lastWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.of(context).size.width.truncate();
    if (_lastWidth != width) {
      _lastWidth = width;
      _loadBanner(width);
    }
  }

  Future<void> _loadBanner(int width) async {
    if (_isLoading) return;

    final unitId = AdService.bannerUnitId;
    if (unitId.isEmpty) return;

    _isLoading = true;

    AdSize adSize = AdSize.banner;
    if (width > 0) {
      final AnchoredAdaptiveBannerAdSize? adaptiveSize =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (adaptiveSize != null) {
        adSize = adaptiveSize;
      }
    }

    if (!mounted) {
      _isLoading = false;
      return;
    }

    await _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;

    debugPrint('Loading BannerAd ($unitId)...');
    _bannerAd = BannerAd(
      adUnitId: unitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _isLoading = false;
          });
          debugPrint('BannerAd loaded successfully.');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

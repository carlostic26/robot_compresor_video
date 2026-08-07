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

    final AnchoredAdaptiveBannerAdSize? adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted) {
      _isLoading = false;
      return;
    }

    final AdSize adSize = adaptiveSize ?? AdSize.banner;

    await _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;

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
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isLoading = false;
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

    return SizedBox(
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

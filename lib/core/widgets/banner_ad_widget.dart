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
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    AdService.canShowBanners.addListener(_onCanShowBannersChanged);
  }

  void _onCanShowBannersChanged() {
    if (!mounted) return;
    if (AdService.canShowBanners.value) {
      if (_bannerAd == null && !_isLoading && _lastWidth != null) {
        _loadBanner(_lastWidth!);
      } else {
        setState(() {});
      }
    } else {
      // Retirar el banner del árbol inmediatamente y liberarlo tras el frame,
      // garantizando que no quede ninguna vista de banner bajo el AppOpenAd.
      final oldAd = _bannerAd;
      _loadGeneration++; // invalida cualquier carga en curso
      setState(() {
        _bannerAd = null;
        _isLoaded = false;
        _isLoading = false;
      });
      if (oldAd != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => oldAd.dispose());
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.of(context).size.width.truncate();
    if (_lastWidth != width) {
      _lastWidth = width;
      if (AdService.canShowBanners.value) {
        _loadBanner(width);
      }
    }
  }

  Future<void> _loadBanner(int width) async {
    if (_isLoading || !AdService.canShowBanners.value) return;

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

    if (!mounted || !AdService.canShowBanners.value) {
      _isLoading = false;
      return;
    }

    await _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;

    debugPrint('Loading BannerAd ($unitId)...');
    final generation = ++_loadGeneration;
    _bannerAd = BannerAd(
      adUnitId: unitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // Descartar respuestas de cargas obsoletas o si los banners
          // fueron apagados (p. ej. por un AppOpenAd).
          if (!mounted ||
              generation != _loadGeneration ||
              !AdService.canShowBanners.value) {
            ad.dispose();
            if (generation == _loadGeneration) _isLoading = false;
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _isLoading = false;
          });
          debugPrint('BannerAd loaded successfully.');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted || generation != _loadGeneration) return;
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
    AdService.canShowBanners.removeListener(_onCanShowBannersChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdService.canShowBanners.value || !_isLoaded || _bannerAd == null) {
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

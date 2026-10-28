import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Estados del anuncio de apertura (AppOpenAd) durante una sesión de la app.
enum AppOpenAdPhase {
  /// Aún no se ha iniciado la sesión (no se ha pasado por LoadingScreen).
  idle,

  /// El usuario está en LoadingScreen (primeros 10s). Si el anuncio carga
  /// aquí, se muestra de inmediato (no hay banners en esta pantalla).
  loadingScreenWindow,

  /// LoadingScreen terminó sin mostrar el anuncio. Se sigue cargando y se
  /// mostrará únicamente cuando el usuario seleccione un video, apagando
  /// antes todos los banners.
  pendingForVideoSelection,

  /// Preparando la visualización: banners apagados, esperando a que se
  /// retiren de pantalla antes de mostrar el anuncio.
  preparingToShow,

  /// El anuncio de apertura se está mostrando.
  showing,

  /// El anuncio ya se mostró (o se descartó) en esta sesión.
  done,
}

class AdService {
  AdService._();

  /// `true` para IDs de producción, o `false` para IDs de prueba.
  static bool isProd = true;

  /// Duración de la pantalla de carga (LoadingScreen). Durante este tiempo
  /// el AppOpenAd tiene prioridad para cargarse y mostrarse.
  static const Duration loadingScreenDuration = Duration(seconds: 10);

  /// Tiempo de espera tras apagar los banners antes de mostrar el AppOpenAd,
  /// para garantizar que la vista nativa del banner se haya retirado.
  static const Duration _bannerTeardownDelay = Duration(milliseconds: 400);

  /// Notificador global que indica si los banners pueden cargarse y mostrarse.
  ///
  /// REGLA: nunca es `true` mientras el AppOpenAd se está preparando o
  /// mostrando, de modo que el anuncio de apertura jamás queda sobre un banner.
  static final ValueNotifier<bool> canShowBanners = ValueNotifier<bool>(false);

  static bool _initialized = false;
  static bool _isShowingFullScreenAd = false;

  static AppOpenAdPhase _appOpenPhase = AppOpenAdPhase.idle;
  static AppOpenAdPhase get appOpenPhase => _appOpenPhase;

  static Timer? _appOpenRetryTimer;
  static Timer? _secondaryAdsPreloadTimer;
  static int _appOpenLoadAttempts = 0;
  static const int _maxAppOpenLoadAttempts = 6;

  // IDs de prueba de ads para Android
  static const String _defaultTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _defaultTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _defaultTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _defaultTestAppOpenId =
      'ca-app-pub-3940256099942544/9257395921';

  static bool get shouldLoadAds {
    final adsEnabled =
        (dotenv.isInitialized ? (dotenv.env['ads_enabled'] ?? 'true') : 'true')
            .toLowerCase() !=
        'false';
    final isTest =
        const bool.fromEnvironment('flutter.test') ||
        Platform.environment.containsKey('FLUTTER_TEST');
    return adsEnabled && !isTest;
  }

  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;
  static AppOpenAd? _appOpenAd;

  static Completer<InterstitialAd?>? _interstitialLoadCompleter;
  static Completer<RewardedAd?>? _rewardedLoadCompleter;
  static bool _isLoadingAppOpenAd = false;

  static String get bannerUnitId {
    if (!shouldLoadAds) return '';
    if (_shouldUseProdAds) {
      return (dotenv.isInitialized ? dotenv.env['banner_prod'] : null) ?? '';
    }
    final testId = dotenv.isInitialized ? dotenv.env['banner_test'] : null;
    return (testId != null && testId.isNotEmpty)
        ? testId
        : _defaultTestBannerId;
  }

  static String get interstitialUnitId {
    if (!shouldLoadAds) return '';
    if (_shouldUseProdAds) {
      return (dotenv.isInitialized ? dotenv.env['interstitial_prod'] : null) ??
          '';
    }
    final testId = dotenv.isInitialized
        ? dotenv.env['interstitial_test']
        : null;
    return (testId != null && testId.isNotEmpty)
        ? testId
        : _defaultTestInterstitialId;
  }

  static String get rewardedUnitId {
    if (!shouldLoadAds) return '';
    if (_shouldUseProdAds) {
      return (dotenv.isInitialized ? dotenv.env['rewarded_prod'] : null) ?? '';
    }
    final testId = dotenv.isInitialized ? dotenv.env['rewarded_test'] : null;
    return (testId != null && testId.isNotEmpty)
        ? testId
        : _defaultTestRewardedId;
  }

  static String get appOpenUnitId {
    if (!shouldLoadAds) return '';
    if (_shouldUseProdAds) {
      return (dotenv.isInitialized ? dotenv.env['app_open_prod'] : null) ?? '';
    }
    final testId = dotenv.isInitialized ? dotenv.env['app_open_test'] : null;
    return (testId != null && testId.isNotEmpty)
        ? testId
        : _defaultTestAppOpenId;
  }

  static bool get _shouldUseProdAds {
    return isProd;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!shouldLoadAds) {
      canShowBanners.value = true;
      return;
    }

    await MobileAds.instance.initialize();

    // Habilitar anuncios de prueba en emuladores y dispositivo físico
    final configuration = RequestConfiguration(
      testDeviceIds: <String>['EMULATOR', '92C3D2A309B4B67DE67A5F10A13F1F43'],
    );
    await MobileAds.instance.updateRequestConfiguration(configuration);

    debugPrint(
      'AdService initialized. Mode: ${isProd ? "PRODUCCIÓN" : "TEST / PRUEBA"}',
    );
  }

  // ---------------------------------------------------------------------------
  // Flujo del anuncio de apertura (AppOpenAd)
  // ---------------------------------------------------------------------------

  /// Inicia la sesión del AppOpenAd. Se llama SOLO desde LoadingScreen, es
  /// decir, cada vez que el usuario abre la app.
  ///
  /// - Banners apagados mientras dure LoadingScreen.
  /// - Si el anuncio carga durante LoadingScreen, se muestra de inmediato.
  static Future<void> startAppOpenSession() async {
    _appOpenRetryTimer?.cancel();
    _secondaryAdsPreloadTimer?.cancel();
    _appOpenLoadAttempts = 0;

    if (!shouldLoadAds) {
      _appOpenPhase = AppOpenAdPhase.done;
      canShowBanners.value = true;
      return;
    }

    _appOpenPhase = AppOpenAdPhase.loadingScreenWindow;
    canShowBanners.value = false;

    await initialize();

    if (appOpenUnitId.isEmpty) {
      debugPrint('AppOpenAd unit ID vacío. Se omite el anuncio de apertura.');
      _completeAppOpenSession();
      return;
    }

    // Prioridad de red al AppOpenAd durante LoadingScreen; los anuncios
    // secundarios se precargan al terminar esa ventana.
    _secondaryAdsPreloadTimer = Timer(loadingScreenDuration, _preloadSecondaryAds);

    _loadAppOpenAd();
  }

  /// Debe llamarse cuando LoadingScreen termina su carga (se habilita el botón
  /// "Continuar"). Si el AppOpenAd no se mostró, queda pendiente para cuando
  /// el usuario seleccione un video, y los banners se habilitan.
  static void onLoadingScreenFinished() {
    if (_appOpenPhase != AppOpenAdPhase.loadingScreenWindow) return;

    debugPrint(
      'AdService: LoadingScreen terminó sin mostrar AppOpenAd. '
      'Queda pendiente para la selección de video.',
    );
    _appOpenPhase = AppOpenAdPhase.pendingForVideoSelection;
    canShowBanners.value = true;
    _preloadSecondaryAds();

    // Seguir intentando cargarlo (sin mostrarlo) si aún no está listo.
    if (_appOpenAd == null && !_isLoadingAppOpenAd) {
      _loadAppOpenAd();
    }
  }

  /// Debe llamarse cuando el usuario ya eligió un video y aparece el widget de
  /// carga. Si hay un AppOpenAd pendiente y ya cargado:
  /// 1. Apaga todos los banners.
  /// 2. Espera a que se retiren de pantalla.
  /// 3. Muestra el AppOpenAd.
  /// 4. Al cerrarlo, vuelve a habilitar los banners.
  static Future<void> showPendingAppOpenAdOnVideoSelected() async {
    if (_appOpenPhase != AppOpenAdPhase.pendingForVideoSelection) return;
    if (_isShowingFullScreenAd) return;

    if (_appOpenAd == null) {
      debugPrint(
        'AdService: AppOpenAd pendiente aún no cargado; se intentará en la '
        'próxima selección de video.',
      );
      if (!_isLoadingAppOpenAd) _loadAppOpenAd();
      return;
    }

    // Bloquear reentradas de inmediato (de forma síncrona).
    _appOpenPhase = AppOpenAdPhase.preparingToShow;

    // 1. Apagar banners en toda la app.
    canShowBanners.value = false;

    // 2. Esperar a que los banners se retiren del árbol y de la vista nativa.
    try {
      await WidgetsBinding.instance.endOfFrame;
    } catch (_) {}
    await Future<void>.delayed(_bannerTeardownDelay);

    if (_appOpenPhase != AppOpenAdPhase.preparingToShow ||
        _appOpenAd == null ||
        _isShowingFullScreenAd) {
      // Algo cambió durante la espera; restaurar estado seguro.
      if (_appOpenPhase == AppOpenAdPhase.preparingToShow) {
        _appOpenPhase = AppOpenAdPhase.pendingForVideoSelection;
      }
      if (!_isShowingFullScreenAd) canShowBanners.value = true;
      return;
    }

    _presentAppOpenAd();
  }

  static void _preloadSecondaryAds() {
    _secondaryAdsPreloadTimer?.cancel();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  /// Finaliza la sesión del AppOpenAd y habilita los banners.
  static void _completeAppOpenSession() {
    _appOpenRetryTimer?.cancel();
    _appOpenPhase = AppOpenAdPhase.done;
    _appOpenAd?.dispose();
    _appOpenAd = null;

    if (!canShowBanners.value) {
      canShowBanners.value = true;
      debugPrint('AdService: Banners habilitados.');
    }

    _preloadSecondaryAds();
  }

  static bool get _appOpenStillWanted =>
      _appOpenPhase == AppOpenAdPhase.loadingScreenWindow ||
      _appOpenPhase == AppOpenAdPhase.pendingForVideoSelection;

  static void _loadAppOpenAd() {
    if (!_appOpenStillWanted) return;
    if (_appOpenAd != null || _isLoadingAppOpenAd) return;

    final adUnitId = appOpenUnitId;
    if (adUnitId.isEmpty) {
      _completeAppOpenSession();
      return;
    }

    _isLoadingAppOpenAd = true;
    _appOpenLoadAttempts++;
    debugPrint('Loading AppOpenAd ($adUnitId) intento $_appOpenLoadAttempts...');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoadingAppOpenAd = false;

          if (!_appOpenStillWanted) {
            ad.dispose();
            return;
          }

          _appOpenAd?.dispose();
          _appOpenAd = ad;
          debugPrint('AppOpenAd loaded successfully (fase: $_appOpenPhase).');

          // Solo se muestra automáticamente si seguimos en LoadingScreen
          // (pantalla sin banners). Si está pendiente, espera a la selección
          // de video.
          if (_appOpenPhase == AppOpenAdPhase.loadingScreenWindow &&
              !_isShowingFullScreenAd) {
            _presentAppOpenAd();
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingAppOpenAd = false;
          _appOpenAd = null;
          debugPrint('AppOpenAd failed to load (code ${error.code}): $error');

          if (_appOpenStillWanted &&
              _appOpenLoadAttempts < _maxAppOpenLoadAttempts) {
            _appOpenRetryTimer?.cancel();
            _appOpenRetryTimer = Timer(
              Duration(seconds: 3 * _appOpenLoadAttempts),
              _loadAppOpenAd,
            );
          }
        },
      ),
    );
  }

  /// Muestra el AppOpenAd ya cargado. Garantiza que los banners estén
  /// apagados durante toda la presentación y solo se habiliten al cerrarlo.
  static void _presentAppOpenAd() {
    final ad = _appOpenAd;
    if (ad == null) return;

    _appOpenAd = null;
    _appOpenRetryTimer?.cancel();
    _isShowingFullScreenAd = true;
    _appOpenPhase = AppOpenAdPhase.showing;
    canShowBanners.value = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        debugPrint('AppOpenAd cerrado por el usuario.');
        _completeAppOpenSession();
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        debugPrint('AppOpenAd failed to show: $error');
        _completeAppOpenSession();
      },
    );

    try {
      ad.show();
    } catch (error, stackTrace) {
      ad.dispose();
      _isShowingFullScreenAd = false;
      debugPrint('AppOpenAd show failed: $error');
      debugPrint('$stackTrace');
      _completeAppOpenSession();
    }
  }

  // ---------------------------------------------------------------------------
  // Intersticiales y recompensados
  // ---------------------------------------------------------------------------

  static int _interstitialAttempts = 0;
  static const int _maxAttempts = 3;

  static void _loadInterstitialAd() {
    final adUnitId = interstitialUnitId;
    if (adUnitId.isEmpty) return;
    if (_interstitialAd != null) return;
    if (_interstitialLoadCompleter != null &&
        !_interstitialLoadCompleter!.isCompleted) {
      return;
    }

    _interstitialLoadCompleter = Completer<InterstitialAd?>();
    debugPrint('Loading InterstitialAd ($adUnitId)...');
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          _interstitialAttempts = 0;
          debugPrint('InterstitialAd loaded successfully.');
          if (_interstitialLoadCompleter != null &&
              !_interstitialLoadCompleter!.isCompleted) {
            _interstitialLoadCompleter!.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAttempts++;
          _interstitialAd = null;
          if (_interstitialLoadCompleter != null &&
              !_interstitialLoadCompleter!.isCompleted) {
            _interstitialLoadCompleter!.complete(null);
          }
          if (_interstitialAttempts <= _maxAttempts) {
            _loadInterstitialAd();
          }
        },
      ),
    );
  }

  static void _loadRewardedAd() {
    final adUnitId = rewardedUnitId;
    if (adUnitId.isEmpty) return;
    if (_rewardedAd != null) return;
    if (_rewardedLoadCompleter != null &&
        !_rewardedLoadCompleter!.isCompleted) {
      return;
    }

    _rewardedLoadCompleter = Completer<RewardedAd?>();
    debugPrint('Loading RewardedAd ($adUnitId)...');
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          debugPrint('RewardedAd loaded successfully.');
          if (_rewardedLoadCompleter != null &&
              !_rewardedLoadCompleter!.isCompleted) {
            _rewardedLoadCompleter!.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load (code ${error.code}): $error');
          _rewardedAd = null;
          if (_rewardedLoadCompleter != null &&
              !_rewardedLoadCompleter!.isCompleted) {
            _rewardedLoadCompleter!.complete(null);
          }
        },
      ),
    );
  }

  static Future<void> showInterstitialAd({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isShowingFullScreenAd ||
        _appOpenPhase == AppOpenAdPhase.preparingToShow) {
      debugPrint(
        'Another full screen ad is already showing. Skipping interstitial.',
      );
      return;
    }

    if (!shouldLoadAds) return;

    if (_interstitialAd == null) {
      if (_interstitialLoadCompleter == null ||
          _interstitialLoadCompleter!.isCompleted) {
        _loadInterstitialAd();
      }
      if (_interstitialLoadCompleter != null &&
          !_interstitialLoadCompleter!.isCompleted) {
        debugPrint(
          'InterstitialAd is currently loading. Awaiting (timeout: ${timeout.inSeconds}s)...',
        );
        try {
          await _interstitialLoadCompleter!.future.timeout(
            timeout,
            onTimeout: () {
              debugPrint('Awaiting InterstitialAd load timed out.');
              return null;
            },
          );
        } catch (e) {
          debugPrint('Error awaiting InterstitialAd: $e');
        }
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('InterstitialAd not available to show.');
      return;
    }

    if (_isShowingFullScreenAd ||
        _appOpenPhase == AppOpenAdPhase.preparingToShow) {
      return;
    }

    _isShowingFullScreenAd = true;
    _interstitialAd = null;

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _loadInterstitialAd();
        debugPrint('InterstitialAd failed to show: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      ad.show();
    } catch (error) {
      ad.dispose();
      _isShowingFullScreenAd = false;
      _loadInterstitialAd();
      debugPrint('InterstitialAd show exception: $error');
      if (!completer.isCompleted) completer.complete();
    }

    await completer.future;
  }

  static Future<bool> showRewardedAd({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isShowingFullScreenAd ||
        _appOpenPhase == AppOpenAdPhase.preparingToShow) {
      return false;
    }
    if (!shouldLoadAds) return false;

    if (_rewardedAd == null) {
      if (_rewardedLoadCompleter == null ||
          _rewardedLoadCompleter!.isCompleted) {
        _loadRewardedAd();
      }
      if (_rewardedLoadCompleter != null &&
          !_rewardedLoadCompleter!.isCompleted) {
        debugPrint(
          'RewardedAd is currently loading. Awaiting (timeout: ${timeout.inSeconds}s)...',
        );
        try {
          await _rewardedLoadCompleter!.future.timeout(
            timeout,
            onTimeout: () {
              debugPrint('Awaiting RewardedAd load timed out.');
              return null;
            },
          );
        } catch (e) {
          debugPrint('Error awaiting RewardedAd: $e');
        }
      }
    }

    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint('No rewarded ad ready');
      return false;
    }

    _isShowingFullScreenAd = true;
    _rewardedAd = null;

    var earnedReward = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (adInstance) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (adInstance, error) {
        adInstance.dispose();
        _isShowingFullScreenAd = false;
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
        debugPrint('RewardedAd failed to show: $error');
      },
    );

    ad.show(
      onUserEarnedReward: (adInstance, reward) {
        earnedReward = true;
      },
    );

    return completer.future;
  }
}

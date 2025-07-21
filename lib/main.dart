import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background handler for notifications
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // You can show a local notification here if needed
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Local notifications setup
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Create notification channel for Android 8+
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel',
    'Default',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;
  bool _hasInternet = true;
  int _selectedIndex = 0;
  final int _unreadNewsCount = 0;
  String? _username;
  String? _password;
  Timer? _loadingTimer;
  InAppWebViewController? _homeController;
  InAppWebViewController? _newsController;
  final String _homeUrl = 'https://mis.cktutas.edu.gh/';
  final String _newsUrl = 'https://cktutasnews.africa/index.php';
  final InAppWebViewSettings _webViewSettings = InAppWebViewSettings(
    javaScriptEnabled: true,
    useOnDownloadStart: true,
    mediaPlaybackRequiresUserGesture: false,
    supportZoom: true,
    cacheEnabled: true,
    useShouldOverrideUrlLoading: true,
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
  );
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _showInternetBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestAllPermissions();
      _initFirebaseMessaging();
    });
    checkInternet();
    _loadCredentials();
    _loadReadNews();
    _fetchUnreadNewsCount();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      checkInternet(result);
    });
    _startLoadingTimer();
  }

  Future<void> requestAllPermissions() async {
    final notificationStatus = await Permission.notification.request();
    final storageStatus = await Permission.storage.request();
    final manageStorageStatus =
        await Permission.manageExternalStorage.request();

    if (notificationStatus.isDenied ||
        storageStatus.isDenied ||
        manageStorageStatus.isDenied) {
      if (mounted && !_showSplash) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permissions Required'),
              content: const Text(
                  'This app needs notification and storage permissions to work properly. Please allow them in settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  Future<void> checkInternet([ConnectivityResult? result]) async {
    var connectivityResult = result ?? await Connectivity().checkConnectivity();
    bool nowHasInternet = connectivityResult != ConnectivityResult.none;
    if (nowHasInternet != _hasInternet) {
      if (mounted) {
        setState(() {
          _hasInternet = nowHasInternet;
          if (!nowHasInternet) {
            _showSplash = false;
            _showInternetBanner = true;
          } else {
            _showInternetBanner = false;
          }
        });
      }
      if (!nowHasInternet) {
        _homeController = null;
        _newsController = null;
      }
    }
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username');
        _password = prefs.getString('password');
      });
    }
  }

  Future<void> _loadReadNews() async {}
  Future<void> _fetchUnreadNewsCount() async {}

  void _initFirebaseMessaging() async {
    await FirebaseMessaging.instance.requestPermission();
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token'); // Print token for debugging
    await FirebaseMessaging.instance.subscribeToTopic('all');

    // Foreground notification handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Show local notification for foreground messages
      if (notification != null && android != null) {
        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title ?? 'Notification',
          notification.body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }

      // Also show dialog if app is open and splash is gone
      if (mounted && !_showSplash) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(notification?.title ?? 'Notification'),
              content: Text(notification?.body ?? ''),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    });
  }

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 15), () {
      if (_showSplash && mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  void showInternetIssueDialog() {
    if (mounted && !_showSplash) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Internet Issue'),
            content: const Text(
                'The page is taking too long to load. Please check your internet connection.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _onTabSelected(int index) {
    if (mounted) {
      setState(() {
        // If already on the tab, refresh the webview
        if (_selectedIndex == index) {
          if (index == 0 && _homeController != null) {
            _homeController!.reload();
          } else if (index == 1 && _newsController != null) {
            _newsController!.reload();
          }
        } else {
          _selectedIndex = index;
        }
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex == 0 && _homeController != null) {
      bool canGoBack = await _homeController!.canGoBack();
      if (canGoBack) {
        await _homeController!.goBack();
        return false;
      }
    } else if (_selectedIndex == 1 && _newsController != null) {
      bool canGoBack = await _newsController!.canGoBack();
      if (canGoBack) {
        await _newsController!.goBack();
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CKT MIS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      ),
      home: Builder(
        builder: (context) {
          Widget mainScaffold;
          if (_showSplash) {
            mainScaffold = const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage('assets/icon.png'),
                      width: 80,
                      height: 80,
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Loading...", style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            );
          } else if (!_hasInternet) {
            mainScaffold = Scaffold(
              appBar: AppBar(
                title: const Text('CKT MIS'),
              ),
              body: const Center(child: Text('No internet connection.')),
            );
          } else if (kIsWeb) {
            mainScaffold = Scaffold(
              appBar: AppBar(
                title: const Text('CKT MIS'),
              ),
              body: Center(
                child: Text(
                  _selectedIndex == 0
                      ? 'Home WebView is not supported on web.'
                      : 'News WebView is not supported on web.',
                ),
              ),
            );
          } else {
            mainScaffold = WillPopScope(
              onWillPop: _onWillPop,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('CKT MIS'),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: _selectedIndex == 0
                              ? Colors.blue
                              : Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        onPressed: () => _onTabSelected(0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: _selectedIndex == 1
                                  ? Colors.blue
                                  : Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.article),
                            label: const Text('News'),
                            onPressed: () => _onTabSelected(1),
                          ),
                          if (_unreadNewsCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _unreadNewsCount > 99
                                      ? '99+'
                                      : '$_unreadNewsCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                body: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(_homeUrl)),
                      initialSettings: _webViewSettings,
                      onWebViewCreated: (controller) {
                        _homeController = controller;
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStart: (controller, url) {
                        _startLoadingTimer();
                      },
                      onLoadStop: (controller, url) async {
                        _loadingTimer?.cancel();
                        if (mounted && _showSplash) {
                          setState(() {
                            _showSplash = false;
                          });
                        }
                        if (_username != null && _password != null) {
                          debugPrint(
                              'Injecting credentials: username=$_username, password=$_password');
                          await Future.delayed(const Duration(seconds: 2));
                          await controller.evaluateJavascript(source: '''
                      (function() {
                        function simulateTyping(element, value) {
                          element.focus();
                          element.value = '';
                          for (let i = 0; i < value.length; i++) {
                            let char = value[i];
                            let eventProps = { key: char, char: char, keyCode: char.charCodeAt(0), which: char.charCodeAt(0), bubbles: true };
                            element.dispatchEvent(new KeyboardEvent('keydown', eventProps));
                            element.value += char;
                            element.dispatchEvent(new KeyboardEvent('keypress', eventProps));
                            element.dispatchEvent(new Event('input', { bubbles: true }));
                            element.dispatchEvent(new KeyboardEvent('keyup', eventProps));
                          }
                          element.dispatchEvent(new Event('change', { bubbles: true }));
                          element.blur();
                        }
                        document.body.style.backgroundColor = '#fff';
                        var userField = document.getElementById('user-name');
                        var passField = document.getElementById('user-password');
                        var form = null;
                        if (userField) {
                          simulateTyping(userField, "${_username!.replaceAll('"', '"')}");
                          userField.setAttribute('value', "${_username!.replaceAll('"', '"')}");
                          form = userField.form;
                        }
                        if (passField) {
                          simulateTyping(passField, "${_password!.replaceAll('"', '"')}");
                          passField.setAttribute('value', "${_password!.replaceAll('"', '"')}");
                          if (!form) form = passField.form;
                        }
                        var btn = document.querySelector('button[type="submit"]');
                        if (btn) {
                          setTimeout(function() { btn.click(); }, 500);
                        } else if (form) {
                          setTimeout(function() { form.submit(); }, 500);
                        }
                        return 'auto-login-attempted';
                      })();
                    ''');
                        } else {
                          await controller.evaluateJavascript(source: '''
                      (function() {
                        document.body.style.backgroundColor = '#fff';
                        return 'bg_set';
                      })();
                    ''');
                        }
                      },
                      onReceivedError: (controller, request, error) {
                        _loadingTimer?.cancel();
                        if (mounted && _showSplash) {
                          setState(() {
                            _showSplash = false;
                          });
                        }
                        if (context.mounted && !_showSplash) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Error'),
                                content: Text(
                                    'Failed to load the page. Please check your internet connection.\n\n${error.description}'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          });
                        }
                      },
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        debugPrint(
                            'WebView console: ${consoleMessage.message}');
                      },
                    ),
                    InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(_newsUrl)),
                      initialSettings: _webViewSettings,
                      onWebViewCreated: (controller) {
                        _newsController = controller;
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStart: (controller, url) {},
                      onLoadStop: (controller, url) async {},
                      onReceivedError: (controller, request, error) {},
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        );
                      },
                      onConsoleMessage: (controller, consoleMessage) {
                        debugPrint(
                            'WebView console: ${consoleMessage.message}');
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          // Small bottom banner for internet warning
          return Stack(
            children: [
              mainScaffold,
              if (!_hasInternet || _showInternetBanner)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 70),
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wifi_off, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'No internet',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
// <-- this is the only thing at the end, no extra semicolon!

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Clé globale pour afficher les banners in-app
  static final GlobalKey<InAppNotifOverlayState> overlayKey = GlobalKey();

  // Clé de navigation passée depuis main()
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize({
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    _navigatorKey = navigatorKey;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Abonnement au topic général par défaut
    await _messaging.subscribeToTopic('general');

    // Notif reçue en foreground → banner in-app
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      if (title.isNotEmpty || body.isNotEmpty) {
        overlayKey.currentState?.show(title: title, body: body);
      }
    });

    // Notif tapée depuis arrière-plan → navigation
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);

    // App lancée depuis une notif alors qu'elle était terminée
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Délai pour laisser le widget tree se construire
      Future.delayed(const Duration(milliseconds: 600), () {
        _handleNavigation(initialMessage);
      });
    }
  }

  /// Navigation vers la page concernée selon le champ 'route' dans data.
  /// Exemple d'envoi FCM : { "data": { "route": "/home" } }
  static void _handleNavigation(RemoteMessage message) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;
    final route = message.data['route'] as String?;
    if (route != null) {
      nav.pushNamed(route);
    }
  }

  /// Active ou désactive les notifications push (topic FCM "general").
  static Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      await _messaging.subscribeToTopic('general');
    } else {
      await _messaging.unsubscribeFromTopic('general');
    }
  }
}

// ─── WIDGET BANNER IN-APP ────────────────────────────────────────────────────

class InAppNotifOverlay extends StatefulWidget {
  final Widget child;
  const InAppNotifOverlay({super.key, required this.child});

  @override
  State<InAppNotifOverlay> createState() => InAppNotifOverlayState();
}

class InAppNotifOverlayState extends State<InAppNotifOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  String _title = '';
  String _body = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void show({required String title, required String body}) async {
    setState(() {
      _title = title;
      _body = body;
    });
    await _controller.forward(from: 0);
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      Positioned(
        top: 0, left: 0, right: 0,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => _controller.reverse(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2729),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_title.isNotEmpty)
                            Text(_title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          if (_body.isNotEmpty)
                            Text(_body,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      )),
                      const Icon(Icons.close, color: Colors.white38, size: 16),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

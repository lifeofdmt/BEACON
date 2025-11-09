import 'package:beacon/views/mobile/auth_service.dart';
import 'package:beacon/views/pages/quest_page.dart';
import 'package:beacon/views/widget/map_widget.dart';
import 'package:flutter/material.dart';
import 'package:beacon/services/beacon_monitor_service.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:location/location.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = false;
  StreamSubscription<BeaconAcceptanceEvent>? _acceptanceSubscription;

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    );

    // Start monitoring for beacon acceptances
    _setupBeaconMonitoring();
  }

  void _setupBeaconMonitoring() {
    final user = authService.value.currentuser;
    if (user != null) {
      BeaconMonitorService.instance.startMonitoring(user.uid);
      _acceptanceSubscription = BeaconMonitorService.instance.acceptanceStream.listen(
        _handleBeaconAcceptance,
      );
    }
  }

  Future<void> _handleBeaconAcceptance(BeaconAcceptanceEvent event) async {
    if (!mounted) return;

    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Someone accepted your beacon "${event.beaconName}"!'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _navigateToAcceptedBeacon(event),
        ),
      ),
    );

    // Auto-navigate to the map after a brief delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _navigateToAcceptedBeacon(event);
    }
  }

  Future<void> _navigateToAcceptedBeacon(BeaconAcceptanceEvent event) async {
    try {
      final user = authService.value.currentuser;
      if (user == null) return;

      // Get creator's current location
      Location location = Location();
      LocationData locationData = await location.getLocation();

      if (event.beaconLocation == null || event.accepterLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location data not available')),
          );
        }
        return;
      }

      if (!mounted) return;

      // Navigate to map: Creator (you) as source, Accepter as destination
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Track to ${event.beaconName}'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Someone is coming to your beacon location!',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: MapWidget(
                      sourceLocation: google_maps.LatLng(
                        locationData.latitude!,
                        locationData.longitude!,
                      ),
                      destinationLocation: google_maps.LatLng(
                        event.accepterLocation!.latitude,
                        event.accepterLocation!.longitude,
                      ),
                      hasAcceptedBeacon: true,
                      currentUserId: user.uid,
                      sourceUserId: user.uid, // Creator is the source
                      destinationUserId: event.accepterId, // Accepter is the destination
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _acceptanceSubscription?.cancel();
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  void _navigateToQuests() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const QuestPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authService.value.currentuser?.uid;

    return Stack(
      children: [
        // Main Map Content
        FractionallySizedBox(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: MapWidget(currentUserId: currentUserId),
          ),
        ),

        // Animated Sidebar
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _sidebarAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _isSidebarExpanded ? 0 : 180 * (1 - _sidebarAnimation.value),
                  0,
                ),
                child: child,
              );
            },
            child: Container(
              width: 240,
              margin: const EdgeInsets.only(top: 80, bottom: 80, right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(24),
                  right: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Sidebar Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primaryContainer,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Quick Menu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildMenuItem(
                          icon: Icons.emoji_events,
                          title: 'Quests',
                          subtitle: 'Complete challenges',
                          color: Colors.amber,
                          onTap: () {
                            _toggleSidebar();
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              _navigateToQuests,
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.leaderboard,
                          title: 'Leaderboard',
                          subtitle: 'View rankings',
                          color: Colors.blue,
                          onTap: () {
                            _toggleSidebar();
                            // TODO: Navigate to leaderboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Leaderboard coming soon!'),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: Icons.stars,
                          title: 'Achievements',
                          subtitle: 'View your badges',
                          color: Colors.purple,
                          onTap: () {
                            _toggleSidebar();
                            // TODO: Navigate to achievements
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Achievements coming soon!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating Toggle Button
        Positioned(
          right: 8,
          top: 100,
          child: GestureDetector(
            onTap: _toggleSidebar,
            child: AnimatedBuilder(
              animation: _sidebarAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _sidebarAnimation.value * 3.14159,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isSidebarExpanded ? Icons.close : Icons.menu,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

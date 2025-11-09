import 'package:flutter/material.dart';
import 'package:beacon/views/pages/create_beacon.dart';
import 'package:beacon/data/constants.dart';
import 'package:beacon/views/mobile/database_service.dart';
import 'package:beacon/views/mobile/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:beacon/views/widget/map_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:beacon/services/beacon_monitor_service.dart';
import 'dart:async';

class BeaconPage extends StatefulWidget {
  const BeaconPage({super.key});

  @override
  State<BeaconPage> createState() => _BeaconPageState();
}

class _BeaconPageState extends State<BeaconPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;
  StreamSubscription<BeaconAcceptanceEvent>? _acceptanceSubscription;
  // Prevent concurrent cancel/complete actions causing duplicate writes
  bool _processingAction = false;

  final List<String> _categories = ['All', ...BeaconCategories.all];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();

    // Delete expired beacons on page load
    _deleteExpiredBeacons();

    // Add listener to search controller to trigger rebuild on text change
    _searchController.addListener(() {
      setState(() {});
    });

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
    BeaconMonitorService.instance.stopMonitoring();
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo, search and categories
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'logo',
                        child: Image.asset(
                          "assets/images/logo_transparent_big.png",
                          height: 150,
                          width: 150,
                          cacheWidth: 300,
                          cacheHeight: 300,
                        ),
                      ),
                      SizedBox(height: 20),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            if (_isSearchFocused)
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onTap: () => setState(() => _isSearchFocused = true),
                          onTapOutside: (_) =>
                              setState(() => _isSearchFocused = false),
                          decoration: InputDecoration(
                            hintText: 'Search Beacons...',
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = category == _selectedCategory;
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: AnimatedScale(
                                duration: Duration(milliseconds: 200),
                                scale: isSelected ? 1.05 : 1.0,
                                child: FilterChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                  elevation: isSelected ? 4 : 0,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  showCheckmark: false,
                                  selectedColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : null,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Active beacon banner
            FutureBuilder<Map<String, dynamic>?>(
              future: _getActiveBeacon(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final activeBeacon = snapshot.data!;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.navigation,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Beacon',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                activeBeacon['name'] ?? 'Untitled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  _navigateToActiveBeacon(activeBeacon),
                              child: Text('View'),
                            ),
                            SizedBox(width: 8),
                            if (authService.value.currentuser?.uid != null)
                              OutlinedButton(
                                onPressed: () => _showCancelConfirmation(
                                  context,
                                  activeBeacon['id'],
                                  authService.value.currentuser!.uid,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                ),
                                child: Text('Cancel'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),

            // Live beacons list
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('beacons').onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  final data = snapshot.data?.snapshot.value;
                  if (data == null) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'No beacons found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }

                  final Map<dynamic, dynamic> map =
                      data as Map<dynamic, dynamic>;
                  var items = map.entries.map((e) {
                    final id = e.key.toString();
                    final m = Map<String, dynamic>.from(e.value as Map);
                    m['id'] = id;
                    return m;
                  }).toList();

                  // filter by status, expiry, and UI filters
                  final now = DateTime.now();
                  items = items.where((m) {
                    final status = (m['status'] ?? 'active').toString();
                    if (status != 'active' && status != 'published') {
                      return false;
                    }

                    // Check if beacon is expired
                    final expiryIso = m['expiryDate']?.toString();
                    if (expiryIso != null) {
                      try {
                        final expiryDate = DateTime.parse(expiryIso);
                        if (now.isAfter(expiryDate)) {
                          // Delete expired beacon asynchronously
                          final beaconId = m['id']?.toString();
                          if (beaconId != null) {
                            FirebaseDatabase.instance
                                .ref('beacons/$beaconId')
                                .remove();
                          }
                          return false; // Don't show expired beacon
                        }
                      } catch (_) {}
                    }

                    final name = (m['name'] ?? '').toString().toLowerCase();
                    final description = (m['description'] ?? '')
                        .toString()
                        .toLowerCase();
                    final cat = (m['category'] ?? '').toString();
                    final q = _searchController.text.toLowerCase();

                    // Search matches name, description, or category
                    final matchesSearch =
                        q.isEmpty ||
                        name.contains(q) ||
                        description.contains(q) ||
                        cat.toLowerCase().contains(q);
                    final matchesCat =
                        _selectedCategory == 'All' || _selectedCategory == cat;
                    return matchesSearch && matchesCat;
                  }).toList();

                  // sort newest first
                  items.sort((a, b) {
                    final aT =
                        DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final bT =
                        DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return bT.compareTo(aT);
                  });

                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'No matching beacons',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _buildBeaconCard(items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fadeAnimation,
        child: FloatingActionButton(
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateBeaconPage()),
            );
            if (!mounted) return;
            if (result == true) {
              // Optionally show feedback
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Beacon created')),
              );
            }
          },
          elevation: 4,
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Future<bool> _checkUserHasActiveBeacon(String userId) async {
    try {
      final snapshot = await DatabaseService().read(path: 'beacons');
      if (snapshot?.value == null) return false;

      final Map<dynamic, dynamic> beacons =
          snapshot!.value as Map<dynamic, dynamic>;

      for (var entry in beacons.entries) {
        final beacon = Map<String, dynamic>.from(entry.value as Map);
        final acceptedBy = beacon['acceptedBy'] as Map?;

        if (acceptedBy != null && acceptedBy.containsKey(userId)) {
          final userAcceptance = acceptedBy[userId];
          if (userAcceptance is Map && userAcceptance['accepted'] == true) {
            // Check if beacon is completed
            final isCompleted = userAcceptance['completed'] == true;
            if (isCompleted) continue; // Skip completed beacons

            // Check if beacon is still active (not expired)
            final expiryIso = beacon['expiryDate']?.toString();
            if (expiryIso != null) {
              try {
                final expiryDate = DateTime.parse(expiryIso);
                if (DateTime.now().isBefore(expiryDate)) {
                  return true; // User has an active accepted beacon
                }
              } catch (_) {}
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking active beacons: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _getActiveBeacon() async {
    try {
      final user = authService.value.currentuser;
      if (user == null) return null;

      final snapshot = await DatabaseService().read(path: 'beacons');
      if (snapshot?.value == null) return null;

      final Map<dynamic, dynamic> beacons =
          snapshot!.value as Map<dynamic, dynamic>;

      for (var entry in beacons.entries) {
        final beaconId = entry.key.toString();
        final beacon = Map<String, dynamic>.from(entry.value as Map);
        final acceptedBy = beacon['acceptedBy'] as Map?;

        if (acceptedBy != null && acceptedBy.containsKey(user.uid)) {
          final userAcceptance = acceptedBy[user.uid];
          if (userAcceptance is Map && userAcceptance['accepted'] == true) {
            // Check if beacon is completed
            final isCompleted = userAcceptance['completed'] == true;
            if (isCompleted) continue; // Skip completed beacons

            // Check if beacon is still active (not expired)
            final expiryIso = beacon['expiryDate']?.toString();
            if (expiryIso != null) {
              try {
                final expiryDate = DateTime.parse(expiryIso);
                if (DateTime.now().isBefore(expiryDate)) {
                  beacon['id'] = beaconId;
                  beacon['userAcceptance'] = userAcceptance;
                  return beacon; // Return the active beacon
                }
              } catch (_) {}
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting active beacon: $e');
      return null;
    }
  }

  Future<void> _navigateToActiveBeacon(Map<String, dynamic> beacon) async {
    try {
      final user = authService.value.currentuser;
      if (user == null) return;

      // Get current location
  Location location = Location();
  LocationData locationData = await location.getLocation();

  if (!mounted) return;

      final beaconLocation = beacon['location'] as Map?;
      if (beaconLocation != null) {
        final destLat = beaconLocation['latitude'] as num?;
        final destLon = beaconLocation['longitude'] as num?;

        if (destLat != null && destLon != null) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text('Route to ${beacon['name'] ?? 'Beacon'}'),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.cancel_outlined),
                      tooltip: 'Cancel Beacon',
                      onPressed: () => _showCancelConfirmation(
                        context,
                        beacon['id'],
                        user.uid,
                      ),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: MapWidget(
                          sourceLocation: google_maps.LatLng(
                            locationData.latitude!,
                            locationData.longitude!,
                          ),
                          destinationLocation: google_maps.LatLng(
                            destLat.toDouble(),
                            destLon.toDouble(),
                          ),
                          hasAcceptedBeacon: true,
                          currentUserId: user.uid,
                          sourceUserId: user.uid,
                          destinationUserId: beacon['createdBy']?.toString(),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _completeBeacon(
                                context,
                                beacon['id'],
                                user.uid,
                              ),
                              icon: Icon(Icons.check_circle_outline),
                              label: Text('Complete'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCancelConfirmation(
                                context,
                                beacon['id'],
                                user.uid,
                              ),
                              icon: Icon(Icons.cancel_outlined),
                              label: Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to beacon: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _deleteExpiredBeacons() async {
    try {
      final snapshot = await DatabaseService().read(path: 'beacons');
      if (snapshot?.value == null) return;

      final Map<dynamic, dynamic> beacons =
          snapshot!.value as Map<dynamic, dynamic>;
      final now = DateTime.now();

      for (var entry in beacons.entries) {
        final beaconId = entry.key.toString();
        final beacon = Map<String, dynamic>.from(entry.value as Map);
        final expiryIso = beacon['expiryDate']?.toString();

        if (expiryIso != null) {
          try {
            final expiryDate = DateTime.parse(expiryIso);
            if (now.isAfter(expiryDate)) {
              // Delete expired beacon
              await FirebaseDatabase.instance.ref('beacons/$beaconId').remove();
          debugPrint('Deleted expired beacon: $beaconId');
            }
          } catch (e) {
            debugPrint('Error parsing date for beacon $beaconId: $e');
          }
        }
      }
    } catch (e) {
  debugPrint('Error deleting expired beacons: $e');
    }
  }

  Widget _buildBeaconCard(Map<String, dynamic> b) {
    final name = b['name']?.toString() ?? 'Untitled Beacon';
    final category = b['category']?.toString() ?? 'Uncategorized';
    final expiryIso = b['expiryDate']?.toString();
    final createdBy = b['createdBy']?.toString();
    final acceptedBy = (b['acceptedBy'] as Map?)?.length ?? 0;

    String format(String? iso) {
      if (iso == null) return 'No expiry';
      try {
        final dt = DateTime.parse(iso);
        return DateFormat.yMMMd().add_jm().format(dt);
      } catch (_) {
        return iso;
      }
    }

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.wifi_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _FavoriteIndicator(beaconId: b['id']?.toString() ?? ''),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text('•', style: TextStyle(color: Colors.grey[400])),
                      Text(
                        'Expires: ${format(expiryIso)}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AuthorLine(uid: createdBy),
                  if (acceptedBy > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Accepted by $acceptedBy user${acceptedBy > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FutureBuilder<bool>(
              future: _checkUserHasActiveBeacon(
                authService.value.currentuser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                final hasActiveBeacon = snapshot.data ?? false;
                final currentUserId = authService.value.currentuser?.uid;
                final isOwnBeacon = createdBy == currentUserId;

                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: (hasActiveBeacon || isOwnBeacon)
                          ? null
                          : () => _acceptBeacon(b),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isOwnBeacon ? 'Your Beacon' : 'Accept'),
                    ),
                    const SizedBox(height: 6),
                    _FavoriteToggle(beaconId: b['id']?.toString() ?? ''),
                    TextButton(
                      onPressed: () => _showBeaconDetails(b),
                      child: const Text('Details'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptBeacon(Map<String, dynamic> beacon) async {
    final user = authService.value.currentuser;
    if (user == null) return;
    final id = beacon['id']?.toString() ?? '';
    if (id.isEmpty) return;

    // Prevent users from accepting their own beacons
    final creatorId = beacon['createdBy']?.toString();
    if (creatorId == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You cannot accept your own beacon.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      // Check if user has already accepted another active beacon
      final hasActiveBeacon = await _checkUserHasActiveBeacon(user.uid);
      if (hasActiveBeacon) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You can only accept one beacon at a time. Complete or cancel your current beacon first.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Get current location of the person accepting
      Location location = Location();
      LocationData locationData = await location.getLocation();

      // Use update at the beacon root to write nested keys
      await DatabaseService().update(
        path: 'beacons/$id',
        data: {
          'acceptedBy/${user.uid}': {
            'accepted': true,
            'acceptedAt': DateTime.now().toIso8601String(),
            'location': {
              'latitude': locationData.latitude,
              'longitude': locationData.longitude,
            },
          },
        },
      );

      // Record acceptance in user's history ONLY if favorited
      try {
        final favSnap = await DatabaseService()
            .read(path: 'userFavorites/${user.uid}/$id');
        if (favSnap?.value != null) {
          final nowIso = DateTime.now().toIso8601String();
          await DatabaseService().update(
            path: 'userHistory/${user.uid}/accepted/$id',
            data: {
              'beaconId': id,
              'name': (beacon['name'] ?? '').toString(),
              'category': (beacon['category'] ?? '').toString(),
              'createdBy': (beacon['createdBy'] ?? '').toString(),
              'acceptedAt': nowIso,
              'status': 'accepted',
              'acceptedLocation': {
                'latitude': locationData.latitude,
                'longitude': locationData.longitude,
              },
            },
          );
        }
      } catch (e) {
        // Non-fatal: history is best-effort
        debugPrint('History conditional write failed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Beacon accepted')));

        // Navigate to map with route information
        // Source: accepter's current location
        // Destination: beacon creator's location
        final beaconLocation = beacon['location'] as Map?;
        if (beaconLocation != null) {
          final destLat = beaconLocation['latitude'] as num?;
          final destLon = beaconLocation['longitude'] as num?;

          if (destLat != null && destLon != null) {
            // Navigate to home page which shows the map
            // The map will show the route from accepter to creator
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: Text('Route to ${beacon['name'] ?? 'Beacon'}'),
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.cancel_outlined),
                        tooltip: 'Cancel Beacon',
                        onPressed: () =>
                            _showCancelConfirmation(context, id, user.uid),
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: MapWidget(
                            sourceLocation: google_maps.LatLng(
                              locationData.latitude!,
                              locationData.longitude!,
                            ),
                            destinationLocation: google_maps.LatLng(
                              destLat.toDouble(),
                              destLon.toDouble(),
                            ),
                            hasAcceptedBeacon: true,
                            currentUserId: user.uid,
                            sourceUserId: user.uid,
                            destinationUserId: beacon['createdBy']?.toString(),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _completeBeacon(context, id, user.uid),
                                icon: Icon(Icons.check_circle_outline),
                                label: Text('Complete'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showCancelConfirmation(
                                  context,
                                  id,
                                  user.uid,
                                ),
                                icon: Icon(Icons.cancel_outlined),
                                label: Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting beacon: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _cancelBeacon(
    BuildContext context,
    String beaconId,
    String userId,
  ) async {
    if (_processingAction) return; // Guard against double taps
    if (beaconId.isEmpty || userId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid beacon/user ID')),
        );
      }
      return;
    }
    try {
      setState(() => _processingAction = true);
      // Remove the user's acceptance from the beacon
      await FirebaseDatabase.instance
          .ref('beacons/$beaconId/acceptedBy/$userId')
          .remove();

      // Update user's history status to cancelled only if history exists
      try {
        final histSnap = await DatabaseService()
            .read(path: 'userHistory/$userId/accepted/$beaconId');
        if (histSnap?.value != null) {
          await DatabaseService().update(
            path: 'userHistory/$userId/accepted/$beaconId',
            data: {
              'status': 'cancelled',
              'cancelledAt': DateTime.now().toIso8601String(),
            },
          );
        }
      } catch (e) {
        debugPrint('History cancel update failed: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beacon cancelled successfully')),
        );
        // Only pop if we are on a pushed route (e.g., map screen), not the main beacon page itself.
        if (Navigator.canPop(context)) {
          // Try-catch to avoid exceptions if already popped by other logic
          try { Navigator.of(context).pop(); } catch (_) {}
        }
        // Trigger rebuild so the active beacon banner updates immediately.
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling beacon: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingAction = false);
    }
  }

  Future<void> _completeBeacon(
    BuildContext context,
    String beaconId,
    String userId,
  ) async {
    if (_processingAction) return; // Guard against double taps
    if (beaconId.isEmpty || userId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid beacon/user ID')),
        );
      }
      return;
    }
    try {
      setState(() => _processingAction = true);
      // Mark the beacon as completed by updating the status
      await DatabaseService().update(
        path: 'beacons/$beaconId/acceptedBy/$userId',
        data: {
          'completed': true,
          'completedAt': DateTime.now().toIso8601String(),
        },
      );

      // Update user's history status to completed only if history exists
      try {
        final histSnap = await DatabaseService()
            .read(path: 'userHistory/$userId/accepted/$beaconId');
        if (histSnap?.value != null) {
          await DatabaseService().update(
            path: 'userHistory/$userId/accepted/$beaconId',
            data: {
              'status': 'completed',
              'completedAt': DateTime.now().toIso8601String(),
            },
          );
        }
      } catch (e) {
        debugPrint('History complete update failed: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beacon completed! Great job!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to beacon list if possible
        if (Navigator.canPop(context)) {
          try { Navigator.of(context).pop(); } catch (_) {}
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing beacon: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingAction = false);
    }
  }

  void _showCancelConfirmation(
    BuildContext context,
    String beaconId,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Cancel Beacon'),
        content: const Text(
          'Are you sure you want to cancel this beacon? You\'ll be able to accept other beacons after cancelling.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No, Keep It'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _cancelBeacon(context, beaconId, userId);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBeaconDetails(Map<String, dynamic> beacon) {
    final name = beacon['name']?.toString() ?? 'Untitled Beacon';
    final description = beacon['description']?.toString() ?? '';
    final category = beacon['category']?.toString() ?? 'Uncategorized';
    final expiryIso = beacon['expiryDate']?.toString();
    final createdBy = beacon['createdBy']?.toString();
    final acceptedBy = (beacon['acceptedBy'] as Map?)?.length ?? 0;
    final status = beacon['status']?.toString() ?? 'active';

    String formatDateTime(String? iso) {
      if (iso == null) return 'No date';
      try {
        final dt = DateTime.parse(iso);
        return DateFormat.yMMMd().add_jm().format(dt);
      } catch (_) {
        return iso;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.wifi_rounded,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _FavoriteToggle(beaconId: beacon['id']?.toString() ?? ''),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 24),
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'Expires',
                  value: formatDateTime(expiryIso),
                ),
                SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.people,
                  label: 'Accepted by',
                  value: '$acceptedBy user${acceptedBy != 1 ? 's' : ''}',
                ),
                SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.info_outline,
                  label: 'Status',
                  value: status,
                ),
                SizedBox(height: 16),
                _AuthorLine(uid: createdBy),
                SizedBox(height: 24),
                FutureBuilder<bool>(
                  future: _checkUserHasActiveBeacon(
                    authService.value.currentuser?.uid ?? '',
                  ),
                  builder: (context, snapshot) {
                    final hasActiveBeacon = snapshot.data ?? false;
                    final currentUserId = authService.value.currentuser?.uid;
                    final isOwnBeacon = createdBy == currentUserId;

                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: (hasActiveBeacon || isOwnBeacon)
                            ? null
                            : () {
                                Navigator.pop(context);
                                _acceptBeacon(beacon);
                              },
                        icon: Icon(Icons.check_circle_outline),
                        label: Text(
                          isOwnBeacon
                              ? 'Your Beacon'
                              : hasActiveBeacon
                                  ? 'Already Accepted Another'
                                  : 'Accept Beacon',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorLine extends StatelessWidget {
  final String? uid;
  const _AuthorLine({required this.uid});

  Future<String> _loadName() async {
    if (uid == null || uid!.isEmpty) return 'Author: Unknown';
    final snap = await DatabaseService().read(path: 'users/$uid');
    final name = (snap?.value as Map?)?['displayName']?.toString();
    return 'Author: ${name ?? uid!}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadName(),
      builder: (context, snapshot) {
        final text = snapshot.data ?? 'Author: ...';
        return Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}

class _FavoriteToggle extends StatefulWidget {
  final String beaconId;
  const _FavoriteToggle({required this.beaconId});

  @override
  State<_FavoriteToggle> createState() => _FavoriteToggleState();
}

class _FavoriteToggleState extends State<_FavoriteToggle> {
  bool _loading = false;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = authService.value.currentuser;
    if (user == null || widget.beaconId.isEmpty) return;
    try {
      final snap = await DatabaseService()
          .read(path: 'userFavorites/${user.uid}/${widget.beaconId}');
      if (mounted) setState(() => _isFav = snap?.value != null);
    } catch (_) {}
  }

  Future<void> _toggle() async {
    final user = authService.value.currentuser;
    if (user == null || widget.beaconId.isEmpty) return;
    setState(() => _loading = true);
    try {
      if (_isFav) {
        await DatabaseService().delete(
          path: 'userFavorites/${user.uid}/${widget.beaconId}',
        );
      } else {
        await DatabaseService().update(
          path: 'userFavorites/${user.uid}',
          data: {
            widget.beaconId: {
              'addedAt': DateTime.now().toIso8601String(),
            },
          },
        );
      }
      if (mounted) setState(() => _isFav = !_isFav);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Favorite toggle failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _loading ? null : _toggle,
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isFav ? Icons.star : Icons.star_border,
              color: _isFav ? Colors.amber : null,
            ),
      tooltip: _isFav ? 'Remove favorite' : 'Add to favorites',
    );
  }
}

class _FavoriteIndicator extends StatefulWidget {
  final String beaconId;
  const _FavoriteIndicator({required this.beaconId});

  @override
  State<_FavoriteIndicator> createState() => _FavoriteIndicatorState();
}

class _FavoriteIndicatorState extends State<_FavoriteIndicator> {
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = authService.value.currentuser;
    if (user == null || widget.beaconId.isEmpty) return;
    try {
      final snap = await DatabaseService()
          .read(path: 'userFavorites/${user.uid}/${widget.beaconId}');
      if (mounted) setState(() => _isFav = snap?.value != null);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFav) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 16),
          SizedBox(width: 4),
          Text(
            'Favorited',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

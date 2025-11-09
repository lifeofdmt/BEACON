import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor beacon acceptances in real-time
class BeaconMonitorService {
  BeaconMonitorService._();
  static final BeaconMonitorService instance = BeaconMonitorService._();

  StreamSubscription<DatabaseEvent>? _subscription;
  String? _currentUserId;
  final _acceptanceController = StreamController<BeaconAcceptanceEvent>.broadcast();
  // Deduplicate recent acceptance emissions to avoid spamming events
  final Map<String, DateTime> _recentEmissions = {};

  /// Stream of beacon acceptance events for the current user's beacons
  Stream<BeaconAcceptanceEvent> get acceptanceStream => _acceptanceController.stream;

  /// Start monitoring beacons created by the specified user
  void startMonitoring(String userId) {
    if (_currentUserId == userId && _subscription != null) {
      return; // Already monitoring for this user
    }

    stopMonitoring();
    _currentUserId = userId;

    // Listen to all beacons
    _subscription = FirebaseDatabase.instance
        .ref('beacons')
        .onValue
        .listen((event) {
      _handleBeaconUpdate(event, userId);
    });

    debugPrint('BeaconMonitorService: Started monitoring for user $userId');
  }

  /// Stop monitoring beacon acceptances
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
    debugPrint('BeaconMonitorService: Stopped monitoring');
  }

  void _handleBeaconUpdate(DatabaseEvent event, String creatorUserId) {
    try {
      final data = event.snapshot.value;
      if (data == null) return;

      final Map<dynamic, dynamic> beacons = data as Map<dynamic, dynamic>;

      for (var entry in beacons.entries) {
        final beaconId = entry.key.toString();
        final beacon = Map<String, dynamic>.from(entry.value as Map);

        // Only process beacons created by the current user
        if (beacon['createdBy']?.toString() != creatorUserId) continue;

        // Check for new acceptances
        final acceptedBy = beacon['acceptedBy'] as Map?;
        if (acceptedBy != null) {
          for (var acceptEntry in acceptedBy.entries) {
            final accepterId = acceptEntry.key.toString();
            final acceptance = Map<String, dynamic>.from(acceptEntry.value as Map);

            // Skip if it's the creator themselves or if not truly accepted
            if (accepterId == creatorUserId) continue;
            if (acceptance['accepted'] != true) continue;

            // Check if this is a new acceptance (within last 5 seconds)
            final acceptedAtStr = acceptance['acceptedAt']?.toString();
            if (acceptedAtStr != null) {
              try {
                final acceptedAt = DateTime.parse(acceptedAtStr);
                final now = DateTime.now();
                final difference = now.difference(acceptedAt);

                // Only emit events for very recent acceptances (within 5 seconds)
                if (difference.inSeconds <= 5) {
                  // De-dupe by beaconId + accepterId for a short window
                  final emissionKey = '$beaconId:$accepterId';
                  final last = _recentEmissions[emissionKey];
                  if (last != null && now.difference(last).inSeconds < 60) {
                    continue; // recently emitted, skip duplicate
                  }
                  final location = acceptance['location'] as Map?;
                  
                  _acceptanceController.add(BeaconAcceptanceEvent(
                    beaconId: beaconId,
                    beaconName: beacon['name']?.toString() ?? 'Untitled Beacon',
                    beaconLocation: beacon['location'] != null 
                        ? BeaconLocation(
                            latitude: (beacon['location']['latitude'] as num).toDouble(),
                            longitude: (beacon['location']['longitude'] as num).toDouble(),
                          )
                        : null,
                    accepterId: accepterId,
                    accepterLocation: location != null
                        ? BeaconLocation(
                            latitude: (location['latitude'] as num).toDouble(),
                            longitude: (location['longitude'] as num).toDouble(),
                          )
                        : null,
                    acceptedAt: acceptedAt,
                    beacon: beacon,
                  ));

                  _recentEmissions[emissionKey] = now;
                }
              } catch (e) {
                debugPrint('Error parsing acceptance date: $e');
              }
            }
          }
        }
      }

      // Clean up old emission keys (older than 2 minutes)
      final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
      _recentEmissions.removeWhere((_, ts) => ts.isBefore(cutoff));
    } catch (e) {
      debugPrint('Error handling beacon update: $e');
    }
  }

  void dispose() {
    stopMonitoring();
    _acceptanceController.close();
  }
}

/// Event emitted when someone accepts a beacon
class BeaconAcceptanceEvent {
  final String beaconId;
  final String beaconName;
  final BeaconLocation? beaconLocation;
  final String accepterId;
  final BeaconLocation? accepterLocation;
  final DateTime acceptedAt;
  final Map<String, dynamic> beacon;

  BeaconAcceptanceEvent({
    required this.beaconId,
    required this.beaconName,
    required this.beaconLocation,
    required this.accepterId,
    required this.accepterLocation,
    required this.acceptedAt,
    required this.beacon,
  });
}

/// Simple location data structure
class BeaconLocation {
  final double latitude;
  final double longitude;

  BeaconLocation({
    required this.latitude,
    required this.longitude,
  });
}

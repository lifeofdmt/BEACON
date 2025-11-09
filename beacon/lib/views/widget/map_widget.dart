import 'dart:async';
import 'dart:ui' as ui;

import 'package:beacon/data/constants.dart';
import 'package:beacon/views/mobile/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';

class MapWidget extends StatefulWidget {
  final google_maps.LatLng? sourceLocation;
  final google_maps.LatLng? destinationLocation;
  final bool hasAcceptedBeacon;
  final String? sourceUserId;
  final String? destinationUserId;
  final String? currentUserId;

  const MapWidget({
    super.key,
    this.sourceLocation,
    this.destinationLocation,
    this.hasAcceptedBeacon = false,
    this.sourceUserId,
    this.destinationUserId,
    this.currentUserId,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final Completer<google_maps.GoogleMapController> _controller = Completer();

  google_maps.LatLng? source;
  google_maps.LatLng? destination;

  List<google_maps.LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  google_maps.BitmapDescriptor sourceIcon =
      google_maps.BitmapDescriptor.defaultMarker;
  google_maps.BitmapDescriptor destinationIcon =
      google_maps.BitmapDescriptor.defaultMarker;
  google_maps.BitmapDescriptor currentIcon =
      google_maps.BitmapDescriptor.defaultMarker;

  // Cache for generated marker bitmaps to avoid recomputing the same images
  final Map<String, google_maps.BitmapDescriptor> _markerCache = {};
  String? _lastRouteKey;

  late Future<LocationData> locationFuture;
  bool _iconsLoaded = false;

  Future<LocationData> fetchInitialLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();
    currentLocation = locationData;
    return locationData;
  }

  void getCurrentLocationStream() async {
    Location location = Location();
    google_maps.GoogleMapController googleMapController =
        await _controller.future;
    location.onLocationChanged.listen((newLoc) {
      currentLocation = newLoc;
      googleMapController.animateCamera(
        google_maps.CameraUpdate.newCameraPosition(
          google_maps.CameraPosition(
            zoom: 13.5,
            target: google_maps.LatLng(newLoc.latitude!, newLoc.longitude!),
          ),
        ),
      );
      setState(() {});
    });
  }

  Future<String?> _getUserCharacter(String? userId) async {
    if (userId == null) return null;
    try {
      final snapshot = await DatabaseService().read(path: 'users/$userId');
      if (snapshot?.value != null) {
        final data = snapshot!.value as Map<dynamic, dynamic>;
        return data['character']?.toString();
      }
    } catch (e) {
      debugPrint('Error fetching user character: $e');
    }
    return null;
  }

  Future<google_maps.BitmapDescriptor> _createCircularMarkerFromAsset(
    String assetPath,
  ) async {
    try {
      // Return cached descriptor if available
      final cached = _markerCache[assetPath];
      if (cached != null) return cached;

      // Load the asset image
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 120,
        targetHeight: 120,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;

      // Create a circular image with border
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final Size size = Size(120, 120);

      // Draw white circle border
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2,
        borderPaint,
      );

      // Draw the image in a circle
      final Paint paint = Paint();
      final Rect rect = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
      final Path clipPath = Path()..addOval(rect);
      canvas.clipPath(clipPath);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        paint,
      );

      // Convert to image
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image finalImage = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      // Convert to bytes
      final ByteData? byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final descriptor = google_maps.BitmapDescriptor.bytes(pngBytes);
      _markerCache[assetPath] = descriptor;
      return descriptor;
    } catch (e) {
      debugPrint('Error creating circular marker: $e');
      // Fallback to default marker
      return google_maps.BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> setCustomMarkerIcon() async {
    // Fetch user characters
    final sourceChar = await _getUserCharacter(widget.sourceUserId);
    final destChar = await _getUserCharacter(widget.destinationUserId);
    final currentChar = await _getUserCharacter(widget.currentUserId);

    // Create markers from character assets
    if (sourceChar != null) {
      sourceIcon = await _createCircularMarkerFromAsset(sourceChar);
    } else {
      sourceIcon = await google_maps.BitmapDescriptor.asset(
        const ImageConfiguration(),
        "assets/images/placeholder.png",
        width: 55,
      );
    }

    if (destChar != null) {
      destinationIcon = await _createCircularMarkerFromAsset(destChar);
    } else {
      destinationIcon = await google_maps.BitmapDescriptor.asset(
        const ImageConfiguration(),
        "assets/images/placeholder.png",
        width: 55,
      );
    }

    if (currentChar != null) {
      currentIcon = await _createCircularMarkerFromAsset(currentChar);
    } else {
      currentIcon = await google_maps.BitmapDescriptor.asset(
        const ImageConfiguration(),
        "assets/images/placeholder.png",
        width: 55,
      );
    }

    setState(() {
      _iconsLoaded = true;
    });
  }

  void getPolyPoints() async {
    // Only get route if a beacon has been accepted
    if (!widget.hasAcceptedBeacon || source == null || destination == null) {
      return;
    }

    // Avoid recomputing the same route repeatedly
    final key =
        '${source!.latitude},${source!.longitude}->${destination!.latitude},${destination!.longitude}';
    if (_lastRouteKey == key && polylineCoordinates.isNotEmpty) {
      return;
    }

    PolylinePoints polylinePoints = PolylinePoints(apiKey: GOOGLE_MAPS_API_KEY);

    // Using PolylineRequest - keeping as-is since RoutesApiRequest has different signature
    // and requires migration to newer routing API
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(source!.latitude, source!.longitude),
        destination: PointLatLng(destination!.latitude, destination!.longitude),
        mode: TravelMode.walking,
      ),
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates = result.points
          .map((point) => google_maps.LatLng(point.latitude, point.longitude))
          .toList();
      _lastRouteKey = key;
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Only set source and destination if a beacon has been accepted
    if (widget.hasAcceptedBeacon) {
      source = widget.sourceLocation;
      destination = widget.destinationLocation;
    }

    locationFuture = fetchInitialLocation();
    // Parallelize initial setup where possible
    Future.wait([
      setCustomMarkerIcon(),
      locationFuture,
    ]).then((_) {
      getCurrentLocationStream();
      getPolyPoints();
    });
  }

  @override
  void dispose() {
    // Clear marker cache to free memory when widget is disposed
    _markerCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocationData>(
      future: locationFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !_iconsLoaded) {
          return Center(
            key: const ValueKey("loading"),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: "hero_1",
                  child: Lottie.asset(
                    "assets/lotties/wolf_walk.json",
                    height: 180,
                    repeat: true,
                    frameRate: FrameRate(30), // Limit frame rate to reduce CPU load
                  ),
                ),
                const SizedBox(height: 20),
                 Container(
                   width: 80,
                   height: 80,
                   decoration: BoxDecoration(
                     color: Theme.of(context).colorScheme.primaryContainer,
                     shape: BoxShape.circle,
                   ),
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: CircularProgressIndicator(
                       strokeWidth: 4,
                       valueColor: AlwaysStoppedAnimation<Color>(
                         Theme.of(context).colorScheme.primary,
                       ),
                     ),
                   ),
                 ),
                 const SizedBox(height: 20),
                const Text(
                  'Loading map...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final location = snapshot.data!;
        final userLocation = google_maps.LatLng(
          location.latitude!,
          location.longitude!,
        );

        // Build markers set based on whether a beacon has been accepted
        Set<google_maps.Marker> markers = {};

        if (widget.hasAcceptedBeacon && source != null && destination != null) {
          // Show source (user's starting location), current location, and destination
          markers.addAll({
            google_maps.Marker(
              markerId: const google_maps.MarkerId("source"),
              position: source!,
              icon: sourceIcon,
              infoWindow: const google_maps.InfoWindow(title: "Starting Point"),
            ),
            google_maps.Marker(
              markerId: const google_maps.MarkerId("currentLocation"),
              position: userLocation,
              icon: currentIcon,
              infoWindow: const google_maps.InfoWindow(title: "Your Location"),
            ),
            google_maps.Marker(
              markerId: const google_maps.MarkerId("destination"),
              position: destination!,
              icon: destinationIcon,
              infoWindow: const google_maps.InfoWindow(
                title: "Beacon Location",
              ),
            ),
          });
        } else {
          // Only show current location when no beacon is accepted
          markers.add(
            google_maps.Marker(
              markerId: const google_maps.MarkerId("currentLocation"),
              position: userLocation,
              icon: currentIcon,
              infoWindow: const google_maps.InfoWindow(title: "Your Location"),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: google_maps.GoogleMap(
            initialCameraPosition: google_maps.CameraPosition(
              target: userLocation,
              zoom: 14.5,
            ),
            polylines: widget.hasAcceptedBeacon
                ? {
                    google_maps.Polyline(
                      polylineId: const google_maps.PolylineId("route"),
                      points: polylineCoordinates,
                      color: Colors.red,
                      width: 6,
                    ),
                  }
                : {},
            markers: markers,
            onMapCreated: (mapController) {
              _controller.complete(mapController);
            },
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:beacon/data/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';

class MapWidget extends StatefulWidget {
  final google_maps.LatLng? sourceLocation;
  final google_maps.LatLng? destinationLocation;
  final bool hasAcceptedBeacon;
  
  const MapWidget({
    super.key,
    this.sourceLocation,
    this.destinationLocation,
    this.hasAcceptedBeacon = false,
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

  google_maps.BitmapDescriptor sourceIcon = google_maps.BitmapDescriptor.defaultMarker;
  google_maps.BitmapDescriptor destinationIcon = google_maps.BitmapDescriptor.defaultMarker;
  google_maps.BitmapDescriptor currentIcon = google_maps.BitmapDescriptor.defaultMarker;


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
    google_maps.GoogleMapController googleMapController = await _controller.future;
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

  Future<void> setCustomMarkerIcon() async {
    sourceIcon = await google_maps.BitmapDescriptor.asset(
      const ImageConfiguration(),
      "assets/images/placeholder.png", width: 55
    );
    destinationIcon = await google_maps.BitmapDescriptor.asset(
      const ImageConfiguration(),
      "assets/images/placeholder.png", width: 55
    );
    currentIcon = await google_maps.BitmapDescriptor.asset(
      const ImageConfiguration(),
      "assets/images/placeholder.png", width: 55);
    setState(() { _iconsLoaded = true; });
  }

  void getPolyPoints() async {
    // Only get route if a beacon has been accepted
    if (!widget.hasAcceptedBeacon || source == null || destination == null) {
      return;
    }

    PolylinePoints polylinePoints = PolylinePoints(apiKey: GOOGLE_MAPS_API_KEY);

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
    setCustomMarkerIcon().then((_) {
      getCurrentLocationStream();
      getPolyPoints();
    });
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
                  child: Lottie.asset("assets/lotties/wolf_walk.json", height: 180),
                ),
                SizedBox(height: 20),
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Lottie.asset("assets/lotties/splash.json", height: 120),
                  ),
                ),
                SizedBox(height: 20),
                Text('Loading map...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        final location = snapshot.data!;
        final userLocation = google_maps.LatLng(location.latitude!, location.longitude!);
        
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
              infoWindow: const google_maps.InfoWindow(title: "Beacon Location"),
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
            polylines: widget.hasAcceptedBeacon ? {
              google_maps.Polyline(
                polylineId: const google_maps.PolylineId("route"),
                points: polylineCoordinates,
                color: Colors.red,
                width: 6,
              ),
            } : {},
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

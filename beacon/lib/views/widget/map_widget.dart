import 'package:beacon/data/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_maps;
import 'package:location/location.dart';
import 'package:lottie/lottie.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  static const google_maps.LatLng source = google_maps.LatLng(37.422054, -122.085324);
  static const google_maps.LatLng destination = google_maps.LatLng(37.411610, -122.071313);

  List<google_maps.LatLng>  polylineCoordinates = [];
  LocationData? currentLocation;

  void getCurrentLocation (){
    Location locaion = Location();
    locaion.getLocation().then((location) {
      currentLocation = location;
    },);
  }

  void getPolyPoints() async
  {
    PolylinePoints polylinePoints = PolylinePoints(apiKey: GOOGLE_MAPS_API_KEY);

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
  request: PolylineRequest(
    origin: PointLatLng(source.latitude, source.longitude), // San Francisco
    destination: PointLatLng(destination.latitude, destination.longitude), // San Jose
    mode: TravelMode.walking,));

    if (result.points.isNotEmpty)
    {
      result.points.forEach((PointLatLng point) => 
      polylineCoordinates.add(google_maps.LatLng(point.latitude, point.longitude)));

      setState(() {});
    }
  }

  @override
  void initState() {
    getCurrentLocation();
    getPolyPoints();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return currentLocation == null ? Hero(tag: "hero_1", child: Lottie.asset("assets/lotties/wolf_walk.json")) : google_maps.GoogleMap(initialCameraPosition: 
    google_maps.CameraPosition(
      target: google_maps.LatLng(currentLocation!.latitude!, currentLocation!.longitude!), zoom: 14.5), 
      polylines: {
        google_maps.Polyline(polylineId: google_maps.PolylineId("route"),
               points: polylineCoordinates, color: Colors.blueGrey, width: 6),

      },
      markers: {
        google_maps.Marker(markerId: const google_maps.MarkerId("currentLocation"),
        position: google_maps.LatLng(currentLocation!.latitude!, currentLocation!.longitude!)),
        const google_maps.Marker(markerId: google_maps.MarkerId("source"), position: source),
        const google_maps.Marker(markerId: google_maps.MarkerId("destination"), position: destination),

      },);
  }
}
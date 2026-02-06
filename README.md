import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
runApp(const AccidentHotspotApp());
}

class AccidentHotspotApp extends StatelessWidget {
const AccidentHotspotApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: "Accident Hotspot Predictor",
home: const LiveMapScreen(),
);
}
}

class LiveMapScreen extends StatefulWidget {
const LiveMapScreen({super.key});

@override
State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
GoogleMapController? mapController;
LatLng? currentPosition;

@override
void initState() {
super.initState();
_getLocation();
}

Future<void> _getLocation() async {
LocationPermission permission = await Geolocator.requestPermission();
if (permission == LocationPermission.denied ||
permission == LocationPermission.deniedForever) {
return;
}

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((Position pos) {
      setState(() {
        currentPosition = LatLng(pos.latitude, pos.longitude);
      });

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(currentPosition!),
        );
      }
    });
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text("Live GPS Tracker"),
centerTitle: true,
),
body: currentPosition == null
? const Center(child: CircularProgressIndicator())
: GoogleMap(
initialCameraPosition: CameraPosition(
target: currentPosition!,
zoom: 17,
),
myLocationEnabled: true,
myLocationButtonEnabled: true,
zoomControlsEnabled: false,
onMapCreated: (controller) => mapController = controller,
),
);
}
}

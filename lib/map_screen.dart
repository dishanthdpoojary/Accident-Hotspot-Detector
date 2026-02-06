// lib/map_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart'; // Import speech package

import 'data/danger_zones.dart';
import 'secrets.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;

  LatLng _currentLocation = const LatLng(12.938859, 74.920614);

  StreamSubscription<Position>? _positionStream;
  final AudioPlayer _player = AudioPlayer();

  bool _isAlertVisible = false;
  bool _isTracking = false;

  MapType _currentMapType = MapType.normal;
  double detectionRadius = 10.0; // small for home testing

  final List<Map<String, double>> _hotspots = DangerZones.zones;

  // Search & routing
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _predictions = [];
  Marker? _destinationMarker;
  Polyline? _routePolyline;
  bool _isRouting = false;

  // Voice Search Variables
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  // UI state
  double _currentZoom = 15.0;
  final EdgeInsets _mapPadding = const EdgeInsets.only(top: 120, bottom: 140);

  final String _mapStyle = '''[
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  }
]''';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initSpeech(); // Initialize speech
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _player.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ---------- Speech Logic ----------
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _searchController.text = result.recognizedWords;
      // Programmatic text updates don't always fire onChanged, so we fetch manually
      _fetchPredictions(result.recognizedWords);
    });
  }

  Future<void> _listen() async {
    if (!_speechEnabled) {
      _showSnack("Speech recognition not available");
      return;
    }
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechToText.listen(onResult: _onSpeechResult);
    }
  }

  // ---------- Location & Hotspot logic ----------
  Future<void> _requestPermissions() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) await Geolocator.openLocationSettings();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnack("Location permission permanently denied.");
      return;
    }
    _startTracking();
  }

  void _startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    Geolocator.getCurrentPosition().then((pos) {
      _updateLocation(LatLng(pos.latitude, pos.longitude), moveCamera: true);
    }).catchError((_) {});

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((Position pos) {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _checkHotspots(_currentLocation);
      if (mounted) setState(() {});
    });
  }

  void _updateLocation(LatLng loc, {bool moveCamera = false}) async {
    _currentLocation = loc;
    if (moveCamera && _mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: loc, zoom: _currentZoom),
      ));
    }
    if (mounted) setState(() {});
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void _checkHotspots(LatLng user) {
    for (var z in _hotspots) {
      final lat = z['lat']!;
      final lng = z['lng']!;
      double d = _distance(user.latitude, user.longitude, lat, lng);
      if (d <= detectionRadius) {
        _triggerAlert();
        return;
      }
    }
    _hideAlert();
  }

  Future<void> _triggerAlert() async {
    if (_isAlertVisible) return;
    setState(() => _isAlertVisible = true);

    if (await Vibration.hasVibrator() ?? false)
      Vibration.vibrate(duration: 1200);
    try {
      await _player.play(AssetSource('alert.mp3'));
    } catch (_) {}
  }

  void _hideAlert() {
    if (!_isAlertVisible) return;
    setState(() => _isAlertVisible = false);
    try {
      _player.stop();
    } catch (_) {}
    try {
      Vibration.cancel();
    } catch (_) {}
  }

  // ---------- Places Autocomplete ----------
  Future<void> _fetchPredictions(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    final url =
    Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': input,
      'key': googleApiKey,
      'components': 'country:in',
      'types': 'geocode'
    });
    try {
      final r = await http.get(url);
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data['status'] == 'OK') {
          final preds = (data['predictions'] as List).map((p) {
            return {
              'description': p['description'] as String,
              'place_id': p['place_id'] as String,
            };
          }).cast<Map<String, String>>().toList();
          setState(() => _predictions = preds);
          return;
        }
      }
    } catch (e) {}
    setState(() => _predictions = []);
  }

  Future<LatLng?> _placeIdToLatLng(String placeId) async {
    final url =
    Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'geometry',
      'key': googleApiKey,
    });
    try {
      final r = await http.get(url);
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final loc = data['result']?['geometry']?['location'];
        if (loc != null) {
          return LatLng(
              (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
        }
      }
    } catch (e) {}
    return null;
  }

  // ---------- Directions ----------
  Future<List<LatLng>?> _fetchRoute(LatLng origin, LatLng dest) async {
    final originStr = '${origin.latitude},${origin.longitude}';
    final destStr = '${dest.latitude},${dest.longitude}';
    final url =
    Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': originStr,
      'destination': destStr,
      'key': googleApiKey,
      'mode': 'driving',
    });
    try {
      final r = await http.get(url);
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        final routes = data['routes'] as List<dynamic>;
        if (routes.isEmpty) return null;
        final poly = routes[0]['overview_polyline']['points'] as String;
        return _decodePolyline(poly);
      }
    } catch (e) {}
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      final latD = lat / 1e5;
      final lngD = lng / 1e5;
      points.add(LatLng(latD, lngD));
    }
    return points;
  }

  Future<void> _onPredictionTap(Map<String, String> pred) async {
    setState(() {
      _predictions = [];
      _searchController.text = pred['description']!;
      _isRouting = true;
    });

    final placeId = pred['place_id']!;
    final dest = await _placeIdToLatLng(placeId);
    if (dest == null) {
      _showSnack('Could not find location');
      setState(() => _isRouting = false);
      return;
    }

    final polyPoints = await _fetchRoute(_currentLocation, dest);
    final destMarker = Marker(
      markerId: const MarkerId('destination'),
      position: dest,
      infoWindow: InfoWindow(title: pred['description']),
    );

    if (polyPoints == null || polyPoints.isEmpty) {
      setState(() {
        _destinationMarker = destMarker;
        _routePolyline = null;
        _isRouting = false;
      });
      await _moveAndFitTo([_currentLocation, dest]);
      return;
    }

    final poly = Polyline(
      polylineId: const PolylineId('route'),
      points: polyPoints,
      color: Colors.blue,
      width: 5,
    );

    setState(() {
      _destinationMarker = destMarker;
      _routePolyline = poly;
      _isRouting = false;
    });

    await _moveAndFitTo([_currentLocation, dest]);
  }

  Future<void> _moveAndFitTo(List<LatLng> pts) async {
    if (pts.isEmpty) return;
    final controller = _mapController ?? await _controller.future;

    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
    final cu = CameraUpdate.newLatLngBounds(bounds, 70);
    try {
      await controller.animateCamera(cu);
    } catch (e) {
      await controller.animateCamera(CameraUpdate.newLatLng(pts.first));
    }
  }

  void _clearRoute() {
    setState(() {
      _destinationMarker = null;
      _routePolyline = null;
      _searchController.clear();
    });
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- Google-Maps-like controls ----------
  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    try {
      await controller.setMapStyle(_mapStyle);
    } catch (_) {}
    if (!_controller.isCompleted) _controller.complete(controller);
  }

  Future<void> _zoomIn() async {
    _currentZoom = (_currentZoom + 1.0).clamp(2.0, 20.0);
    final ctrl = await _controller.future;
    await ctrl.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  Future<void> _zoomOut() async {
    _currentZoom = (_currentZoom - 1.0).clamp(2.0, 20.0);
    final ctrl = await _controller.future;
    await ctrl.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  Future<void> _centerOnUser() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _currentZoom = 17.0;
      final ctrl = await _controller.future;
      await ctrl.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation, zoom: _currentZoom)));
    } catch (e) {
      _showSnack('Could not get current location');
    }
  }

  void _cycleMapType() {
    setState(() {
      if (_currentMapType == MapType.normal)
        _currentMapType = MapType.hybrid;
      else if (_currentMapType == MapType.hybrid)
        _currentMapType = MapType.terrain;
      else
        _currentMapType = MapType.normal;
    });
  }

  // ---------- Build UI ----------
  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{..._markers};
    if (_destinationMarker != null) markers.add(_destinationMarker!);

    final polylines = <Polyline>{};
    if (_routePolyline != null) polylines.add(_routePolyline!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accident Hotspot Map'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.clear), onPressed: _clearRoute),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
            initialCameraPosition:
            CameraPosition(target: _currentLocation, zoom: _currentZoom),
            markers: markers,
            circles: _circles,
            polylines: polylines,
            onMapCreated: _onMapCreated,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            zoomControlsEnabled: false,
            padding: _mapPadding,
          ),

          // Top search bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _predictions = []);
                                },
                              ),
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic_off : Icons.mic,
                                color: _isListening ? Colors.red : Colors.grey,
                              ),
                              onPressed: _listen,
                            ),
                          ],
                        ),
                        hintText: _isListening
                            ? 'Listening...'
                            : 'Search place or address',
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onChanged: (v) {
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (v == _searchController.text) _fetchPredictions(v);
                        });
                      },
                      onSubmitted: (v) {
                        if (_predictions.isNotEmpty)
                          _onPredictionTap(_predictions.first);
                      },
                    ),
                  ),
                  if (_predictions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6),
                          ]),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _predictions.length,
                        itemBuilder: (context, i) {
                          final p = _predictions[i];
                          return ListTile(
                            dense: true,
                            title: Text(p['description']!),
                            onTap: () => _onPredictionTap(p),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (_isAlertVisible)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.red,
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "⚠ Accident-prone zone nearby! Slow down!",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Google-maps like control column
          Positioned(
            right: 12,
            bottom: 140,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'center_me',
                  mini: false,
                  backgroundColor: Colors.white,
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'map_type',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _cycleMapType,
                  child: const Icon(Icons.map, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // markers and circles
  Set<Marker> get _markers {
    final base = _hotspots.map((z) {
      final lat = z['lat']!;
      final lng = z['lng']!;
      return Marker(
        markerId: MarkerId("${lat}_$lng"),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Danger Zone"),
      );
    }).toSet();
    if (_destinationMarker != null) base.add(_destinationMarker!);
    return base;
  }

  Set<Circle> get _circles {
    return _hotspots.map((z) {
      final lat = z['lat']!;
      final lng = z['lng']!;
      return Circle(
        circleId: CircleId("${lat}_${lng}_circle"),
        center: LatLng(lat, lng),
        radius: detectionRadius,
        strokeColor: Colors.red,
        strokeWidth: 2,
        fillColor: Colors.red.withOpacity(0.25),
      );
    }).toSet();
  }
}
🚧 Accident Hotspot Alert App (Flutter)

A Flutter-based mobile application that works like Google Maps and alerts users when they enter accident-prone zones using live GPS tracking, vibration, sound alerts, and on-map visual warnings.

📱 Features
🗺️ Maps & Navigation

Google Maps integration

Map types:

Default

Hybrid (Satellite + Labels)

Terrain

Live current location tracking

Custom “Center on Me” button

Zoom in / zoom out controls

Google-Maps-style UI

⚠️ Accident Hotspot Detection

Predefined accident-prone zones (centralized data file)

Radius-based detection (configurable, e.g. 10m for testing)

Automatic alerts when user enters a danger zone:

🔊 Sound alert

📳 Vibration

🚨 On-screen warning popup

Visual danger zones using markers + circles

🔍 Search & Routing

Google Places autocomplete search

Search by place or address

Fetch and display driving routes

Draw route polylines on the map

Destination marker handling

Clear route option

🛠️ Tech Stack
Layer	Technology
Framework	Flutter (Dart)
Maps	google_maps_flutter
Location	geolocator
Alerts	vibration, audioplayers
APIs	Google Maps, Places, Directions
Platform	Android
📂 Project Structure
lib/
 ├── main.dart
 ├── map_screen.dart
 ├── data/
 │    └── danger_zones.dart
 ├── secrets.dart
assets/
 └── alert.mp3
android/
 └── AndroidManifest.xml

🔑 API Configuration

This app uses one Google Maps API key with the following enabled:

✅ Maps SDK for Android

✅ Places API

✅ Directions API

Add your API key in:

android/app/src/main/AndroidManifest.xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />

lib/secrets.dart
const String googleApiKey = "YOUR_API_KEY_HERE";

📍 Danger Zones Configuration

All accident-prone locations are stored in a separate file for easy maintenance.

lib/data/danger_zones.dart
class DangerZones {
  static const List<Map<String, double>> zones = [
    {"lat": 12.9258, "lng": 74.8770},
    {"lat": 12.9262, "lng": 74.8582},
    {"lat": 12.938859, "lng": 74.920614}, // Home test zone
  ];
}

▶️ How to Run
flutter clean
flutter pub get
flutter run


📱 Make sure GPS is enabled on your phone
🔊 Volume should be ON to hear alerts

⚙️ Customization

Change detection radius:

double detectionRadius = 10.0; // meters


Switch default map type:

MapType.hybrid


Replace alert sound:

assets/alert.mp3

🚀 Future Enhancements

Firebase authentication (Google Sign-In)

Backend-driven accident hotspot updates

Offline map caching

Speed-based alert severity

iOS support

📸 Screenshots

(Add screenshots here)

📄 License

This project is for academic / demo purposes.
You’re free to modify and extend it.

🙌 Author

Developed by Dishanth
Engineering Student | Flutter Developer

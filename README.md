# Accident Hotspot Alert System (Flutter)

A real-time, location-aware mobile application built with Flutter that detects accident-prone zones and alerts users instantly using live GPS tracking, map visualization, sound, and vibration — similar to Google Maps safety alerts.

---

## Overview

The **Accident Hotspot Alert System** is designed to improve road safety by notifying users when they enter predefined accident-prone areas. The application continuously monitors the user's live location and triggers alerts when the user comes within a specified radius of danger zones.

This project is developed as an **engineering mini-project** and demonstrates practical use of mobile GIS, real-time tracking, and Google Maps APIs.

---

## Key Features

### Real-Time Location Tracking
- Live GPS tracking using device sensors
- Continuous background location updates
- Smooth camera movement following the user

### Accident Hotspot Detection
- Centralized danger-zone dataset
- Radius-based proximity detection
- Configurable detection distance (meters)

### User Alerts
- Audio alert (siren sound)
- Device vibration
- On-screen warning banner
- Visual danger zones on the map

### Map & Navigation
- Google Maps integration
- Map modes:
  - Default
  - Hybrid (Satellite + Labels)
  - Terrain
- Custom zoom controls
- “Center on my location” button (Google Maps style)

### Search & Routing
- Google Places Autocomplete
- Address and place search
- Driving route generation
- Route polyline rendering
- Destination marker
- Clear route option

---

## Technology Stack

| Category | Technology |
|--------|------------|
| Framework | Flutter (Dart) |
| Maps | Google Maps SDK |
| Location | Geolocator |
| Search | Google Places API |
| Routing | Google Directions API |
| Alerts | Audioplayers, Vibration |
| Platform | Android |

---

## Project Structure

lib/
├── main.dart
├── map_screen.dart
├── data/
│ └── danger_zones.dart
├── secrets.dart
assets/
└── alert.mp3
android/
└── AndroidManifest.xml


---

##  Accident Hotspot Data

Danger zones are stored separately for scalability and easy updates.

```dart
class DangerZones {
  static const List<Map<String, double>> zones = [
    {"lat": 12.9258, "lng": 74.8770},
    {"lat": 12.9262, "lng": 74.8582},
    {"lat": 12.938859, "lng": 74.920614} // test zone
  ];
}
 Google Maps API Configuration
Enable the following APIs in Google Cloud Console:

Maps SDK for Android

Places API

Directions API

AndroidManifest.xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY" />
secrets.dart
const String googleApiKey = "YOUR_API_KEY";
▶️ Running the Application
flutter clean
flutter pub get
flutter run
✅ Requirements
Android device or emulator

Location services enabled

Internet connection

Sound enabled (for alerts)

⚙️ Configuration Options
Change Detection Radius
double detectionRadius = 10.0; // meters
Change Default Map View
MapType.hybrid
🚗 Use Cases
Driver safety assistance

Accident-prone zone awareness

Smart navigation systems

Academic GIS and mobile systems projects

🔮 Future Enhancements
Firebase authentication (Google Sign-In)

Cloud-based hotspot updates

Speed-based warning logic

Offline map support

iOS deployment

👨‍💻 Author
Dishanth
Engineering Student
Mini Project – Mobile Application Development

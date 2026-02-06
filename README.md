# Accident Hotspot Alert System (Flutter)

A real-time, location-aware mobile app built with Flutter that detects accident-prone zones and alerts users instantly using live GPS tracking, map visualization, sound, and vibration — similar to Google Maps safety alerts.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Configuration](#configuration)
- [Permissions](#permissions)
- [Running the App](#running-the-app)
- [Danger Zone Data](#danger-zone-data)
- [Customizing Detection Radius](#customizing-detection-radius)
- [Troubleshooting](#troubleshooting)
- [Future Enhancements](#future-enhancements)
- [License & Author](#license--author)

---

## Overview

The Accident Hotspot Alert System notifies users when they enter predefined accident-prone areas. The app continuously monitors the user's location, displays the user and danger zones on Google Maps, and triggers audio, vibration, and visual alerts when the user comes within a configured radius.

---

## Key Features

- Real-time GPS tracking with smooth camera follow
- Radius-based accident hotspot detection
- Visual danger zones rendered on Google Maps
- Audio (siren) alert + device vibration + on-screen banner
- Map modes: Default, Hybrid, Terrain
- Google Places Autocomplete and Directions routing
- Clear route / Center-on-my-location controls

---

## Technology Stack

- Flutter (Dart)
- Google Maps SDK (Android)
- Geolocator (location)
- Google Places API and Directions API
- Audioplayers, Vibration
- Platform target: Android

---

## Project Structure

lib/
- main.dart
- map_screen.dart
- data/
- danger_zones.dart
- secrets.dart

assets/
- alert.mp3

android/
- AndroidManifest.xml

---

## Setup & Installation

1. Ensure Flutter is installed and set up:
   - Flutter SDK (stable)
   - Android SDK and device/emulator

2. Clone the repo:
   ```bash
   git clone <your-repo-url>
   cd <project-folder>
   ```

3. Add required packages to `pubspec.yaml` and fetch dependencies:
   ```bash
   flutter pub get
   ```

4. Add `alert.mp3` to `assets/` and declare it in `pubspec.yaml` under `assets:`:
   ```yaml
   flutter:
     assets:
       - assets/alert.mp3
   ```

---

## Configuration

1. Enable APIs in Google Cloud Console:
   - Maps SDK for Android
   - Places API
   - Directions API

2. Provide your API key in two places:

- AndroidManifest.xml (inside `<application>`):

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

- lib/secrets.dart:

```dart
// lib/secrets.dart
const String googleApiKey = "YOUR_API_KEY_HERE";
```

Make sure `YOUR_API_KEY_HERE` is replaced with your actual API key and that the key has Android app restrictions (package name + SHA-1) set appropriately if you restrict it.

3. Danger zones are stored in `lib/data/danger_zones.dart`. Example:

```dart
// lib/data/danger_zones.dart
class DangerZones {
  static const List<Map<String, double>> zones = [
    {"lat": 12.9258, "lng": 74.8770},
    {"lat": 12.9262, "lng": 74.8582},
    {"lat": 12.938859, "lng": 74.920614},
  ];
}
```

---

## Permissions

Update `android/app/src/main/AndroidManifest.xml` with required permissions:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<!-- If background tracking or Android 10+ background location is needed -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

If you use foreground services for background location updates, declare the service and required attributes as per Android docs.

Also request runtime permissions from the user in the app (Geolocator or permission_handler can help).

---

## Running the App

- For development on an Android device/emulator:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

- Ensure:
  - Location services on the device are enabled.
  - Internet connection is available.
  - Sound is enabled to hear the alert.

---

## Customizing Detection Radius

In your map screen or detection logic (e.g., `map_screen.dart`), you can configure the detection radius:

```dart
double detectionRadiusMeters = 10.0; // in meters
```

The detection logic typically computes distance between current location and each danger zone (Haversine/geodesic) and triggers alerts if distance <= detectionRadiusMeters.

---

## Example Detection Logic (conceptual)

```dart
import 'package:geolocator/geolocator.dart';

bool isInDangerZone(Position user, double zoneLat, double zoneLng, double radiusMeters) {
  double distance = Geolocator.distanceBetween(
    user.latitude,
    user.longitude,
    zoneLat,
    zoneLng,
  );
  return distance <= radiusMeters;
}
```

Trigger audio (audioplayers), vibration, and show a banner when `true`.

---

## Troubleshooting

- Map shows "For development purposes only" — make sure billing is enabled and API key is correct and not restricted incorrectly.
- Location not updating on emulator — enable location simulation or test on a real device.
- Directions or Places returning ZERO_RESULTS — ensure the Places/Directions API is enabled and quotas are available.
- Alert sound not playing — confirm `assets/alert.mp3` exists and is declared in `pubspec.yaml`.

---

## Future Enhancements

- Cloud-based hotspot updates (Firebase)
- User authentication (Google Sign-In)
- Speed-based warnings and dynamic radius
- Offline map support and iOS deployment
- Improved UI/UX and accessibility

---

## License & Author

Author: Dishanth  
Engineering Student
Mobile Application Developer

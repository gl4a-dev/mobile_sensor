# Mobile Sensor

**Mobile Sensor** is a Flutter application designed for background data collection, monitoring, and network diagnostics, including mobile networks, Wi-Fi, geolocation, and connection quality.

The primary objective of the project is to act as a crowdsourced mobile measurement probe, accumulating georeferenced network performance data to feed a cloud database built for spatial analysis and generating **coverage and signal quality heatmaps**.

## Technologies & Architecture

The project is structured around a modular architecture focused on offline resilience, safe concurrency using *Isolates*, and minimal battery consumption impact.

* **Framework:** Flutter (Android)
* **Background Management:** `flutter_background_service` (Secondary headless Isolate)
* **Local Persistence:** SQLite (`sqflite`) storing raw JSON payloads
* **Geographic Collection:** `geolocator`
* **Network Metrics:** `network_info_plus`, `wifi_scan`, `mobile_operator_info`
* **Quality of Service (QoS) Testing:** Custom engine for Ping, Jitter, and Throughput diagnostics

## Key Features

* **Georeferenced Scanning:** High-precision coordinate capture (latitude, longitude, altitude, and accuracy).
* **Connection Diagnostics:** Active interface identification (Wi-Fi vs. Mobile Data), mobile operator, MCC/MNC codes, and connected SSIDs/BSSIDs.
* **Wi-Fi Spectrum Mapping:** Environmental scan of nearby access points and signal strength (RSSI) levels.
* **Quality of Service (QoS) Metrics:** Active tests measuring latency (ping), jitter stability, and connection success rate.
* **Scheduled Background Execution:** Customizable background scheduler (configurable execution intervals, active days, and time windows).
* **Offline Resilience Layer:** Temporary local storage enabling retry mechanisms and sync routines with cloud services.

> **Note on Noise Sensor (`NoiseService`):** Ambient noise measurement via microphone is temporarily disabled during background execution cycles to avoid permission conflicts and excessive battery consumption on Android.


## Local Persistence Structure

To optimize device performance during background execution, collected measurements are serialized as full JSON documents and stored locally in a single SQLite table:

```sql
CREATE TABLE measurements (
    id TEXT PRIMARY KEY,
    payload TEXT NOT NULL,
    created_at TEXT NOT NULL
);
```

### Sample JSON Document (`payload`)

```json
{
    "id": "1710000000000000",
    "timestamp": "2026-09-01T10:30:00.000Z",
    "location": {
        "latitude": -23.55052,
        "longitude": -46.633308,
        "accuracy": 12.5,
        "altitude": 760.0,
        "provider": "gps"
    },
    "internet_quality": {
        "ping": 24.5,
        "jitter": 3.2,
        "ping_success_rate": 1.0,
        "download_mbps": 45.8,
        "upload_mbps": 12.3,
        "started_at": "2026-09-01T10:29:50.000Z",
        "duration_ms": 10000,
        "endpoint": "speed.cloudflare.com",
        "success": true,
        "error": null
    },
    "network_status": {
        "connection_type": "wifi",
        "connected_ssid": "MyNetwork_5G",
        "connected_bssid": "AA:BB:CC:DD:EE:FF",
        "is_metered": false,
        "has_internet": true,
        "is_validated": true,
        "mobile_operator": null,
        "mobile_country_code": null,
        "mobile_network_code": null
    },
    "wifi_list": [
        {
            "ssid": "MyNetwork_5G",
            "bssid": "AA:BB:CC:DD:EE:FF",
            "rssi": -45
        }
    ],
    "noise_measurement": null
}
```

## Getting Started

### Prerequisites

* **Flutter SDK:** 3.x or higher
* **Android SDK:** Configured for `compileSdk` 37
* **Physical Android Device:** Recommended for testing network sensors and background collection services.

### Installation Steps

1. Clone the repository:
```bash
git clone <repository-url>
cd mobile_sensor
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the project on a connected physical device:
```bash
flutter run
```

## User Interface & Features

The application provides a dashboard for interacting with sensors, visualizing collected data, and controlling automated execution:

* **Manual Measurement Execution:** Trigger instant, on-demand sensor scans directly from the main screen to test geolocation, QoS, and surrounding Wi-Fi networks in real time.
* **Local Measurement History:** Browse, inspect, and filter historical data stored on the device. Users can review full JSON payloads, verify timestamps, check individual sensor readings, or clear local storage.
* **Background Configuration & Scheduling:** Customize automated sampling policies through a dedicated settings panel:
  * Enable or disable the periodic background service.
  * Adjust collection intervals (e.g., every 15, 30, or 60 minutes).
  * Select active collection days (e.g., weekdays vs. weekends).
  * Define daily time windows or toggle 24-hour continuous sampling.
* **Status Monitoring:** Real-time visibility into active network interfaces, GPS accuracy, and background service state via Android notifications.
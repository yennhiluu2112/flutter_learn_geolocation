import 'dart:convert';
import 'dart:typed_data';

import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:learn_geolocation/permission_helper.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  GoogleMapController? mapController;
  List<Marker> markers = [];
  List<LatLng> locations = [];
  LatLng? currentPosition;
  String locationStr = '';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        final isGranted = await Permission.location.request().isGranted;
        if (!isGranted && mounted) {
          PermissionHelper.request(context);
        }
        break;
      default:
    }
  }

  void getCurrentLocation() async {
    final location = await bg.BackgroundGeolocation.getCurrentPosition();
    setState(() {
      currentPosition = LatLng(
        location.coords.latitude,
        location.coords.longitude,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();

    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      onLocation(location);
    });

    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - $location');
    });

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    // 2.  Configure the plugin
    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10,
        stopOnTerminate: true,
        startOnBoot: true,
        debug: true,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
      ),
    ).then((bg.State state) {
      if (!state.enabled) {
        // 3.  Start the plugin.
        bg.BackgroundGeolocation.start();
      }
    });
  }

  void onLocation(bg.Location location) {
    final ll = LatLng(location.coords.latitude, location.coords.longitude);
    final marker = Marker(
      markerId: MarkerId(location.uuid),
      position: ll,
    );
    setState(() {
      markers.add(marker);
      locations.add(ll);
      locationStr = '$locationStr \n $ll';
    });
    mapController?.moveCamera(CameraUpdate.newLatLng(ll));
  }

  void onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  void saveFile() async {
    final bytes = Uint8List.fromList(utf8.encode(locationStr));
    await DocumentFileSavePlus().saveFile(
      bytes,
      'location_file.txt',
      'text/plain',
    );
  }

  @override
  Widget build(BuildContext context) {
    return currentPosition == null
        ? const SizedBox()
        : Scaffold(
            body: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                GoogleMap(
                  onMapCreated: onMapCreated,
                  myLocationEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: currentPosition!,
                    zoom: 20,
                  ),
                  markers: markers.toSet(),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('poylineId'),
                      points: locations,
                    )
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: FilledButton(
                    onPressed: saveFile,
                    child: const Text('Save File'),
                  ),
                ),
              ],
            ),
          );
  }
}

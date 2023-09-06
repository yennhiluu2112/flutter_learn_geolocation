import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'permission_helper.dart';

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
  bool isPermissionGranted = false;

  @override
  void initState() {
    super.initState();

    Future.wait([
      getPermissionStatus(),
      getCurrentLocation(),
    ]);

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
        startOnBoot: false,
        debug: false,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        locationAuthorizationRequest: 'Always',
        allowIdenticalLocations: true,
        preventSuspend: true,
        showsBackgroundLocationIndicator: false,
      ),
    ).then((bg.State state) async {
      if (!state.enabled) {
        await bg.BackgroundGeolocation.start();
        await bg.BackgroundGeolocation.changePace(true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        PermissionHelper.handlePermission(context);
        break;
      default:
    }
  }

  Future<void> getCurrentLocation() async {
    final location = await bg.BackgroundGeolocation.getCurrentPosition();
    setState(() {
      currentPosition = LatLng(
        location.coords.latitude,
        location.coords.longitude,
      );
    });
  }

  Future<void> getPermissionStatus() async {
    final isGranted = await PermissionHelper.handlePermission(context);
    setState(() {
      isPermissionGranted = isGranted;
    });
  }

  void onLocation(bg.Location location) {
    final ll = LatLng(location.coords.latitude, location.coords.longitude);
    print(ll);
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

  void saveFileZip() async {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();

    final bytes = Uint8List.fromList(utf8.encode(locationStr));
    File file = await File('${appDocDirectory.path}/locations.txt').create();
    file.writeAsBytesSync(bytes);

    var encoder = ZipFileEncoder();
    encoder.create('${appDocDirectory.path}/locations.zip');
    encoder.addFile(file);
    encoder.close();

    // await DocumentFileSavePlus().saveFile(
    //   bytes,
    //   'location_file.txt',
    //   'text/plain',
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !isPermissionGranted
          ? const SizedBox()
          : currentPosition == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text('Getting current position...'),
                    ],
                  ),
                )
              : Stack(
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
                        onPressed: saveFileZip,
                        child: const Text('Save File'),
                      ),
                    ),
                  ],
                ),
    );
  }
}

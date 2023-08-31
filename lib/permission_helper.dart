import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'ok_cancel_dialog.dart';

class PermissionHelper {
  const PermissionHelper._();

  static final geolocatorPlatform = GeolocatorPlatform.instance;

  static void showDialogOpenSettings(
    BuildContext context,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => OkCancelDialog(
        title: 'Permission denied',
        contentText: message,
        onPressed: () async {
          if (await Geolocator.openLocationSettings()) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
      ),
    );
  }

  static Future<bool> handlePermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        showDialogOpenSettings(context, 'Location service is not enabled');
      }
      return false;
    }

    permission = await geolocatorPlatform.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        permission = await geolocatorPlatform.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            showDialogOpenSettings(context, 'Location permission denied');
          }
        }
        return false;
      case LocationPermission.deniedForever:
        if (context.mounted) {
          showDialogOpenSettings(context, 'Location permission denied forever');
        }
        return false;
      case LocationPermission.unableToDetermine:
        if (context.mounted) {
          showDialogOpenSettings(
              context, 'Location permission not able to determine');
        }
        return false;
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        print('Permission granted');
        return true;
    }
  }
}

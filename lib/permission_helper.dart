import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart' as settings;

import 'ok_cancel_dialog.dart';

class PermissionHelper {
  PermissionHelper._();

  static Future<bool> request(
    BuildContext? context,
  ) async {
    try {
      const permission = Permission.location;
      final status = await permission.status;
      switch (status) {
        case PermissionStatus.granted:
        case PermissionStatus.limited:
          return true;
        case PermissionStatus.denied:
          final requestStatus = await permission.request();
          if (requestStatus == PermissionStatus.permanentlyDenied &&
              TargetPlatform.android == defaultTargetPlatform) {
            showDialogOpenSettings(context!);
          }
          return requestStatus.isGranted;
        case PermissionStatus.restricted:
        case PermissionStatus.permanentlyDenied:
          if (context != null && context.mounted) {
            showDialogOpenSettings(context);
          }
          return false;
        case PermissionStatus.provisional:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  static void showDialogOpenSettings(
    BuildContext context,
  ) {
    var message = 'Please allow us to get your location';

    showDialog(
      context: context,
      builder: (context) {
        return OkCancelDialog(
          title: 'Geolocation',
          contentText: message,
          onPressed: () {
            Future.delayed(
              const Duration(milliseconds: 150),
              () {
                settings.AppSettings.openAppSettings();
              },
            );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

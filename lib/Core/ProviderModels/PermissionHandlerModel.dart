import 'package:flutter/cupertino.dart';
import 'package:location/location.dart';

class PermissionHandlerModel extends ChangeNotifier {
  Location location = Location();

  bool isLocationPerGiven = false;
  bool isLocationSerGiven = false;

  PermissionHandlerModel() {
    location.changeSettings(accuracy: LocationAccuracy.low);
    location.hasPermission().then((isGiven) {
      if (isGiven == PermissionStatus.granted || isGiven == PermissionStatus.grantedLimited) {
        isLocationPerGiven = true;
        location.serviceEnabled().then((isEnabled) {
          if (isEnabled) {
            isLocationSerGiven = true;
          } else {
            isLocationSerGiven = false;
          }
          notifyListeners();
        });
      } else {
        isLocationPerGiven = false;
      }
      notifyListeners();
    });
  }

  Future<bool> checkAppLocationGranted() async {
    final status = await location.hasPermission();
    return status == PermissionStatus.granted || status == PermissionStatus.grantedLimited;
  }

  requestAppLocationPermission() {
    location.requestPermission().then((isGiven) {
      isLocationPerGiven = isGiven == PermissionStatus.granted || isGiven == PermissionStatus.grantedLimited;
      notifyListeners();
    });
  }

  Future<bool> checkLocationServiceEnabled() {
    return location.serviceEnabled();
  }

  requestLocationServiceToEnable() {
    location.requestService().then((isGiven) {
      isLocationSerGiven = isGiven;
      notifyListeners();
    });
  }
}

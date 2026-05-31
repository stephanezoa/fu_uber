import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fu_uber/Core/Constants/Constants.dart';
import 'package:fu_uber/Core/Constants/DemoData.dart';
import 'package:fu_uber/Core/Constants/colorConstants.dart';
import 'package:fu_uber/Core/Models/Drivers.dart';
import 'package:fu_uber/Core/Repository/mapRepository.dart';
import 'package:fu_uber/Core/Utils/LogUtils.dart';
import 'package:fu_uber/Core/Utils/Utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:location/location.dart' as location;

/// A viewModel kind of class for handling Map related information and updating.
/// We are using Provider with notifyListeners() for the sake of simplicity but will update with dynamic approach
/// Provider : https://pub.dev/packages/provider

class MapModel extends ChangeNotifier {
  final mapScreenScaffoldKey = GlobalKey<ScaffoldState>();

  // Tag for Logs
  static const TAG = "MapModel";

  //Current Position and Destination Position and Pickup Point
  LatLng? _currentPosition, _destinationPosition, _pickupPosition;

  // Default Camera Zoom
  double currentZoom = 19;

  // Set of all the markers on the map
  final Set<Marker> _markers = <Marker>{};

  // Set of all the polyLines/routes on the map
  final Set<Polyline> _polyLines = <Polyline>{};

  // Pickup Predictions using Places Api, It is the list of Predictions we get from the textchanges the PickupText field in the mainScreen
  List<Prediction>? pickupPredictions = [];

  //Same as PickupPredictions but for destination TextField in mainScreen
  List<Prediction>? destinationPredictions = [];

  //Map Controller
  GoogleMapController? _mapController;

  // Map Repository for connection to APIs
  final MapRepository _mapRepository = MapRepository();

  // FormField Controller for the pickup field
  TextEditingController pickupFormFieldController = TextEditingController();

  // FormField Controller for the destination field
  TextEditingController destinationFormFieldController =
  TextEditingController();

  // Location Object to get current Location
  final location.Location _location = location.Location();

  // currentPosition Getter
  LatLng? get currentPosition => _currentPosition;

  // destinationPosition Getter
  LatLng? get destinationPosition => _destinationPosition;

  // pickupPosition Getter
  LatLng? get pickupPosition => _pickupPosition;

  // MapRepository Getter
  MapRepository get mapRepo => _mapRepository;

  // MapController Getter
  GoogleMapController? get mapController => _mapController;

  // Markers Getter
  Set<Marker> get markers => _markers;

  // PolyLines Getter
  Set<Polyline> get polyLines => _polyLines;

  double get randomZoom => 13.0 + Random().nextInt(4);

  /// Default Constructor
  MapModel() {
    ProjectLog.logIt(TAG, "MapModel Constructor", "...");

    //getting user Current Location
    _getUserLocation();

    fetchNearbyDrivers(DemoData.nearbyDrivers);

    //A listener on _location to always get current location and update it.
    _location.onLocationChanged.listen((event) async {
      final lat = event.latitude;
      final lng = event.longitude;
      if (lat == null || lng == null) return;
      _currentPosition = LatLng(lat, lng);
      markers.removeWhere((marker) {
        return marker.markerId.value == Constants.currentLocationMarkerId;
      });
      markers.remove(
          Marker(markerId: MarkerId(Constants.currentLocationMarkerId)));
      markers.add(Marker(
          markerId: MarkerId(Constants.currentLocationMarkerId),
          position: _currentPosition!,
          rotation: (event.heading ?? 0.0) - 78,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(
            await Utils.getBytesFromAsset("images/currentUserIcon.png", 280),
          )));
      notifyListeners();
    });
  }

  ///Callback whenever data in Pickup TextField is changed
  ///onChanged()
  onPickupTextFieldChanged(String string) async {
    ProjectLog.logIt(TAG, "onPickupTextFieldChanged", string);
    if (string.isEmpty) {
      pickupPredictions = null;
      notifyListeners();
    } else {
      try {
        await mapRepo.getAutoCompleteResponse(string).then((response) {
          updatePickupPointSuggestions(response.predictions);
          ProjectLog.logIt(
              TAG, "UpdatePickupPredictions", response.predictions.toString());
        });
      } catch (e) {
        print(e);
      }
    }
  }

  ///Callback whenever data in destination TextField is changed
  ///onChanged()
  onDestinationTextFieldChanged(String string) async {
    ProjectLog.logIt(TAG, "onDestinationTextFieldChanged", string);
    if (string.isEmpty) {
      destinationPredictions = null;
      notifyListeners();
    } else {
      try {
        await mapRepo.getAutoCompleteResponse(string).then((response) {
          updateDestinationSuggestions(response.predictions);
          ProjectLog.logIt(TAG, "UpdateDestinationPredictions",
              response.predictions.toString());
        });
      } catch (e) {
        print(e);
      }
    }
  }

  ///Getting current Location : Works only one time
  void _getUserLocation() async {
    ProjectLog.logIt(TAG, "getUserCurrentLocation", "...");

    _location.getLocation().then((data) async {
      final lat = data.latitude;
      final lng = data.longitude;
      if (lat == null || lng == null) return;
      _currentPosition = LatLng(lat, lng);
      _pickupPosition = _currentPosition;

      ProjectLog.logIt(
          TAG, "Initial Position is ", _currentPosition.toString());

      pickupFormFieldController.text = await mapRepo
          .getPlaceNameFromLatLng(LatLng(lat, lng));
      updatePickupMarker();
      notifyListeners();
    });
  }

  ///Creating a Route
  void createCurrentRoute(String encodedPoly) {
    ProjectLog.logIt(TAG, "createCurrentRoute", encodedPoly);
    _polyLines.add(Polyline(
        polylineId: PolylineId(Constants.currentRoutePolylineId),
        width: 3,
        geodesic: true,
        points: Utils.convertToLatLng(Utils.decodePoly(encodedPoly)),
        color: ConstantColors.PrimaryColor));
    notifyListeners();
  }

  ///Adding or updating Destination Marker on the Map
  updateDestinationMarker() async {
    final dest = destinationPosition;
    if (dest == null) return;

    ProjectLog.logIt(
        TAG, "updateDestinationMarker", dest.toString());
    markers.add(Marker(
        markerId: MarkerId(Constants.destinationMarkerId),
        position: dest,
        draggable: true,
        onDragEnd: onDestinationMarkerDragged,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.fromBytes(
            await Utils.getBytesFromAsset("images/destinationIcon.png", 80))));
    notifyListeners();
  }

  ///Adding or updating Destination Marker on the Map
  updatePickupMarker() async {
    final pick = pickupPosition;
    if (pick == null) return;
    ProjectLog.logIt(TAG, "updatePickupMarker", pick.toString());
    _markers.add(Marker(
        markerId: MarkerId(Constants.pickupMarkerId),
        position: pick,
        draggable: true,
        onDragEnd: onPickupMarkerDragged,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.fromBytes(
            await Utils.getBytesFromAsset("images/pickupIcon.png", 80))));
    notifyListeners();
  }

  ///Updating Pickup Suggestions
  updatePickupPointSuggestions(List<Prediction>? predictions) {
    ProjectLog.logIt(
        TAG, "updatePickupPointSuggestions", predictions.toString());
    pickupPredictions = predictions;
    notifyListeners();
  }

  ///Updating Destination
  updateDestinationSuggestions(List<Prediction>? predictions) {
    ProjectLog.logIt(
        TAG, "updateDestinationSuggestions", predictions.toString());
    destinationPredictions = predictions;
    notifyListeners();
  }

  ///on Destination predictions item clicked
  onDestinationPredictionItemClick(Prediction prediction) async {
    updateDestinationSuggestions(null);
    final desc = prediction.description ?? "";
    ProjectLog.logIt(
        TAG, "onDestinationPredictionItemClick", desc);
    destinationFormFieldController.text = desc;
    _destinationPosition =
    await mapRepo.getLatLngFromAddress(desc);
    onDestinationPositionChanged();
    notifyListeners();
  }

  ///on Pickup predictions item clicked
  onPickupPredictionItemClick(Prediction prediction) async {
    updatePickupPointSuggestions(null);
    final desc = prediction.description ?? "";
    ProjectLog.logIt(
        TAG, "onPickupPredictionItemClick", desc);
    pickupFormFieldController.text = desc;

    _pickupPosition =
    await mapRepo.getLatLngFromAddress(desc);
    onPickupPositionChanged();
    notifyListeners();
  }

  // ! SEND REQUEST
  void sendRouteRequest() async {
    ProjectLog.logIt(TAG, "sendRouteRequest", "...");
    final pick = _pickupPosition;
    final dest = _destinationPosition;
    if (pick == null) {
      pickupFormFieldController.text = "This is required";
      return;
    } else if (dest == null) {
      destinationFormFieldController.text = "This is required";
      return;
    }
    await mapRepo
        .getRouteCoordinates(pick, dest)
        .then((route) {
      createCurrentRoute(route);
      notifyListeners();
    });
  }

  /// listening to camera moving event
  void onCameraMove(CameraPosition position) {
    currentZoom = position.zoom;
    notifyListeners();
  }

  /// when map is created
  void onMapCreated(GoogleMapController controller) {
    ProjectLog.logIt(TAG, "onMapCreated", "null");
    _mapController = controller;
    rootBundle.loadString('assets/mapStyle.txt').then((string) {
      _mapController?.setMapStyle(string);
    });
    notifyListeners();
  }

  bool checkDestinationOriginForNull() {
    if (pickupPosition == null || destinationPosition == null) {
      return false;
    } else {
      return true;
    }
  }

  void randomMapZoom() {
    _mapController
        ?.animateCamera(CameraUpdate.zoomTo(15.0 + Random().nextInt(5)));
  }

  void onMyLocationFabClicked() {
    ProjectLog.logIt(TAG, "Moving to Current Position", "...");
    final pos = currentPosition;
    if (pos != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          pos, 15.0 + Random().nextInt(4)));
    }
  }

  void fetchNearbyDrivers(List<Driver>? list) {
    if (list != null && list.isNotEmpty) {
      list.forEach((driver) async {
        markers.add(Marker(
            markerId: MarkerId(driver.driverId),
            infoWindow: InfoWindow(title: driver.carDetail.carCompanyName),
            position: driver.currentLocation,
            anchor: const Offset(0.5, 0.5),
            icon: BitmapDescriptor.fromBytes(
                await Utils.getBytesFromAsset("images/carIcon.png", 80))));
        notifyListeners();
      });
    }
  }

  void onDestinationPositionChanged() {
    final dest = destinationPosition;
    if (dest == null) return;
    updateDestinationMarker();
    _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(dest, randomZoom));
    if (pickupPosition != null) sendRouteRequest();
    notifyListeners();
  }

  void onPickupPositionChanged() {
    final pick = pickupPosition;
    if (pick == null) return;
    updatePickupMarker();
    _mapController
        ?.animateCamera(CameraUpdate.newLatLngZoom(pick, randomZoom));
    if (destinationPosition != null) sendRouteRequest();
    notifyListeners();
  }

  void onPickupMarkerDragged(LatLng value) async {
    _pickupPosition = value;
    pickupFormFieldController.text =
    await mapRepo.getPlaceNameFromLatLng(value);
    onPickupPositionChanged();
    notifyListeners();
  }

  void onDestinationMarkerDragged(LatLng latLng) async {
    _destinationPosition = latLng;
    destinationFormFieldController.text =
    await mapRepo.getPlaceNameFromLatLng(latLng);
    onDestinationPositionChanged();
    notifyListeners();
  }

  void panelIsOpened() {
    if (checkDestinationOriginForNull()) {
      animateCameraForOD();
    }
  }

  void animateCameraForOD() {
    final pick = pickupPosition;
    final dest = destinationPosition;
    if (pick == null || dest == null) return;

    final southwest = LatLng(
      min(pick.latitude, dest.latitude),
      min(pick.longitude, dest.longitude),
    );
    final northeast = LatLng(
      max(pick.latitude, dest.latitude),
      max(pick.longitude, dest.longitude),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
              northeast: northeast, southwest: southwest),
          100),
    );
  }

  void panelIsClosed() {
    onMyLocationFabClicked();
  }
}

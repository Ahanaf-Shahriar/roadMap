import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:map/data/source/marker_firebase.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MapHome extends StatefulWidget {
  const MapHome({super.key});

  @override
  State<MapHome> createState() => _MyAppState();
}

class _MyAppState extends State<MapHome> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(23.8103, 90.4125);
  final Set<Marker> _markers = {};
  String type = "";
  List<Map<String, dynamic>> _markerData = [];
  String _currentFilter = "all";
  int _filterIndex = 0;
  final List<String> _filterOptions = [
    "pothole",
    "construction",
    "waterlogging",
    "all"
  ];
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _getCurrentLocation();
    fetchMarkers();
    //fetchData();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.location.request().isGranted) {
      // Permission granted
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Permission Denied"),
          content: const Text(
              "Location permissions are required to display the map."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _showConfirmationDialog(BuildContext context, String type, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: Text("Report for $type"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _addMarkerAtCurrentLocation(index);
                Navigator.of(context).pop();
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    if (!(await Geolocator.isLocationServiceEnabled())) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }



  Future<void> fetchMarkers() async {
    try {
      Query query = FirebaseFirestore.instance.collection('markers');
      if (_currentFilter != "all") {
        query = query.where('type', isEqualTo: _currentFilter);
      }

      QuerySnapshot querySnapshot = await query.get();
      _markers.clear();
      _markerData.clear();

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        String streetName = data['streetname'];
        String locality = data['locality'];
        Timestamp timestamp = data['timestamp'];
        DateTime dateTime = timestamp.toDate();
        String typ = data['type'];

        BitmapDescriptor markerColor;
        switch (typ) {
          case "pothole":
            markerColor =
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
            break;
          case "construction":
            markerColor = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen);
            break;
          case "waterlogging":
            markerColor =
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
            break;
          default:
            markerColor = BitmapDescriptor.defaultMarker;
        }

        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(latitude, longitude),
            icon: markerColor,
            infoWindow: InfoWindow(
              title: typ.isNotEmpty ? typ : "Marker",
              snippet: "Lat: $latitude, Lng: $longitude",
            ),
          ),
        );
        _markerData.add({
          'type': typ,
          'streetName': streetName,
          'locality': locality,
          'date': DateFormat('d MMM yyyy h:mm a').format(dateTime),
        });
      }
      setState(() {});
      print("Markers fetched and added to map and list.");
    } catch (e) {
      print("Failed to fetch markers: $e");
    }
  }

  Future<void> _onMapTapped(LatLng position) async {
    String streetName = "unknown";
    String locality = "unknown";
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        streetName = placemarks.last.street ?? "Unknown";
        locality = placemarks.last.subLocality ?? "Unknown";
      }
    } catch (e) {
      print("Error getting street name: $e");
    }

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(position.toString()),
          position: position,
          infoWindow: InfoWindow(
            title: "Custom Marker",
            snippet: "Lat: ${position.latitude}, Lng: ${position.longitude}",
          ),
        ),
      );
    });
    addMarkerToFirestore(
        position.latitude, position.longitude, "pothole", streetName, locality);
  }

  _addMarkerAtCurrentLocation(int index) async {
    BitmapDescriptor markerColor;
    String streetName = "Unknown";
    String locality = "Unknown";

    // Reverse geocode to get street name
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );
      if (placemarks.isNotEmpty) {
        streetName = placemarks.last.street ?? "Unknown";
        locality = placemarks.last.subLocality ?? "Unknown";
      }
    } catch (e) {
      print("Error getting street name: $e");
    }

    switch (index) {
      case 1:
        markerColor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        addMarkerToFirestore(_currentPosition.latitude,
            _currentPosition.longitude, "pothole", streetName, locality);
        break;
      case 2:
        markerColor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        addMarkerToFirestore(_currentPosition.latitude,
            _currentPosition.longitude, "construction", streetName, locality);
        break;
      case 3:
        markerColor =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        addMarkerToFirestore(_currentPosition.latitude,
            _currentPosition.longitude, "waterlogging", streetName, locality);
        break;
      default:
        markerColor = BitmapDescriptor.defaultMarker;
    }

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker_$index'),
          position: _currentPosition,
          icon: markerColor,
          infoWindow: InfoWindow(
            title: "Marker $index",
            snippet: "Street: $streetName",
          ),
        ),
      );

      // Animate the camera to the marker
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Maps Home')),
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 11.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              trafficEnabled: true,
              onTap: _onMapTapped,
            ),
            DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.1,
              maxChildSize: 1.0,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                _showConfirmationDialog(context, "PotHole", 1);
                              },
                              onDoubleTap: () => _addMarkerAtCurrentLocation(1),
                              child: const CircleAvatar(
                                child: Icon(Icons.remove_road_outlined),
                              ),
                            ),
                            const SizedBox(width: 24),
                            InkWell(
                              onTap: () {
                                _showConfirmationDialog(
                                    context, "Road Construction", 2);
                              },
                              onDoubleTap: () => _addMarkerAtCurrentLocation(2),
                              child: const CircleAvatar(
                                child: Icon(Icons.construction),
                              ),
                            ),
                            const SizedBox(width: 24),
                            InkWell(
                              onTap: () {
                                _showConfirmationDialog(
                                    context, "Water Logging", 3);
                              },
                              onDoubleTap: () => _addMarkerAtCurrentLocation(3),
                              child: const CircleAvatar(
                                child: Icon(Icons.water),
                              ),
                            ),
                            const SizedBox(width: 24),
                            InkWell(
                              onTap: () => _addMarkerAtCurrentLocation(3),
                              child: const CircleAvatar(
                                child: Icon(Icons.water),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            height: 250.0,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(
                                  color: Colors.blueAccent, width: 2.0),
                            ),
                            child: ListView.builder(
                              itemCount: _markerData.length,
                              itemBuilder: (BuildContext context, int index) {
                                final marker = _markerData[index];
                                String streetName = marker['streetName'] ?? "Unknown Street";
                                String date = marker['date'] ?? "No Date";
                                String type = marker['type'] ?? "No Type";

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        streetName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        date,
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        type,
                                        style: const TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: 8.0,
                            top : -20 ,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _filterIndex =
                                      (_filterIndex + 1) % _filterOptions.length;
                                  _currentFilter = _filterOptions[_filterIndex];
                                });
                                fetchMarkers(); // Fetch markers with the updated filter
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Text(_filterOptions[_filterIndex]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12,),
                      Container(
                        height: 250.0,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                              color: Colors.blueAccent, width: 2.0),
                        ),

                      ),

                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

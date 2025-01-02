import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addMarkerToFirestore(double latitude, double longitude, String type , String streetName , String locality) async {
  try {
    await FirebaseFirestore.instance.collection('markers').add({
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'streetname' : streetName,
      'locality' : locality,
    });
    print("Marker added successfully!");
  } catch (e) {
    print("Failed to add marker: $e");
  }
}





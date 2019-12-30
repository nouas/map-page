import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_lookup/utility/my_navigator.dart';
import 'package:location/location.dart';
import 'package:flutter/cupertino.dart';





class MapView extends StatefulWidget {
  // initialize the email string to show it
  final String name;
  MapView({Key key, @required this.name}) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController mapController;
  Location location = new Location();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final Firestore _database = Firestore.instance;
  bool mapToggle = false;
  var currentLocation;
  bool clientsToggle = false;
  Set<Marker> _markers = {};
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId selectedMarker;


  @override
  void initState() {
    super.initState();
    Geolocator().getCurrentPosition().then((pos) {
      setState(() {
        currentLocation = pos;
        mapToggle = true;
        getMarkers();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size;
    return
        // Prevent user from going back step by wrapping with willpopscope
        WillPopScope(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20),
              children: <Widget>[
                DrawerHeader(
                  child: Text(
                    'Health Lookup',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.greenAccent[700],
                        fontSize: 27,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: RaisedButton(
                        color: Colors.blue[500],
                        textColor: Colors.white,
                        disabledColor: Colors.grey,
                        disabledTextColor: Colors.black,
                        padding: EdgeInsets.all(8.0),
                        splashColor: Colors.blueAccent[500],
                        shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(40.0),
                        ),
                        child: Text('Log Out'),
                        onPressed: () {
                          signOut();
                          MyNavigator.goToLoginPage(context);
                          _scaffoldKey.currentState.openEndDrawer();
                        },
                      ),
                    ),
                    Text(widget.name),
                  ],
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          title: Text('You\'re logged in!'),
        ),
        body: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: screenWidth.height - 80,
              child: mapToggle
                  ? GoogleMap(
                      onMapCreated: _onMapCreated,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: true,
                      compassEnabled: true,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(currentLocation.latitude,
                            currentLocation.longitude),
                        zoom: 17.0,
                      ),
                      markers: Set<Marker>.of(markers.values),
                    )
                  : Center(child: Text('Loading... Please Wait!')),
            ),
            Positioned(
                right: 10,
                bottom: 30,
                child: FloatingActionButton(
                  heroTag: 2,
                  child: Icon(Icons.filter_list),
                  onPressed: () => _animateToUser(),
                )),
            Positioned(
                right: 10,
                bottom: 100,
                child: FloatingActionButton(
                  heroTag: 1,
                  child: Icon(Icons.my_location),
                  onPressed: () => _animateToUser(),
                )),
          ],
        ),
      ),
      onWillPop: () async => false,
    );
  }

  // create an instance of mapcontroller to manage
  _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });
  }

  // Changes the mapview to center on the user location
  _animateToUser() async {
    location.onLocationChanged();
    var pos = await location.getLocation();
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(pos.latitude, pos.longitude), zoom: 17.0)));
  }


  getMarkers() async {
    _database.collection('providers2').getDocuments().then((docs){
      //print(docs);
    setState(() {
      for (int i = 0; i < docs.documents.length; i++) {
        _markers.add(Marker(
            markerId: MarkerId(docs.documents[i].data['Grade']),
            position: LatLng(double.parse(docs.documents[i].data['latitude']),
                double.parse(docs.documents[i].data['Latitude'])),
                  
            infoWindow: InfoWindow(
                title: docs.documents[i].data['name.en'],
                snippet: docs.documents[i].data['phone'],
                )));
      }
      return docs;
    });});
 }

  void _updateMarkers(List<DocumentSnapshot> documentList) {
    int _markerIdCounter = 1;
    final String markerIdVal = 'marker_id_$_markerIdCounter';
    final MarkerId markerId = MarkerId(markerIdVal);
    print(documentList);
    markers.clear();
    documentList.forEach(
      (DocumentSnapshot document) {
        GeoPoint pos = document.data['position']['geopoint'];
        var marker = Marker(
            markerId: markerId,
            position: LatLng(pos.latitude, pos.longitude),
            infoWindow:
                InfoWindow(title: 'Location', snippet: document.data['Grade']));
        setState(() {
          markers[markerId] = marker;
        });
      },
    );
  }


  static Future<void> signOut() async {
    return FirebaseAuth.instance.signOut();
  }
}

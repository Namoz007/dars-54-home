import 'package:dars_74/services/my_location_services.dart';
import 'package:dars_74/services/yandex_map_services..dart';
import 'package:dars_74/views/widgets/serach_city.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final searchCity = TextEditingController();
  final locationServices = LocationService();
  late YandexMapController mapController;
  List<MapObject>? polylines;
  List<Point> points = [];
  bool isLoading = false;

  Point myCurrentLocation = const Point(
    latitude: 41.2856806,
    longitude: 69.9034646,
  );

  Point najotTalim = const Point(
    latitude: 41.2856806,
    longitude: 69.2034646,
  );

  void initState() {
    super.initState();
    Future.delayed(Duration.zero,() async{
      setState(() {
        isLoading = true;
      });
      // await LocationService.init();
      setState(() {
        isLoading = false;
      });
    });
  }

  void onMapCreated(YandexMapController controller) {
    mapController = controller;
    mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: najotTalim,
          zoom: 20,
        ),
      ),
    );
    setState(() {});
  }

  void onCameraPositionChanged(
      CameraPosition position,
      CameraUpdateReason reason,
      bool finished,
      ) async {
    myCurrentLocation = position.target;
    // final init = await LocationService.init();

    if (points.length == 2) {
      polylines =
      await YandexMapService.getDirection(points[0], points[1]);
    }

    setState(() {});
  }

  void watchMyLocation() {
    LocationService.getLiveLocation().listen((location) {
      if(location != null){
        if(myCurrentLocation.longitude != location.longitude || myCurrentLocation.latitude != location.latitude){
          setState(() {
            myCurrentLocation = Point(latitude: location.latitude!, longitude: location.longitude!);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchCity,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Search city",
            suffixIcon: InkWell(onTap: ()async{
              if(searchCity.text.isNotEmpty){
                final resultWithSession = await YandexSuggest.getSuggestions(
                  text: searchCity.text,
                  boundingBox: const BoundingBox(
                      northEast: Point(latitude: 56.0421, longitude: 38.0284),
                      southWest: Point(latitude: 55.5143, longitude: 37.24841)),
                  suggestOptions: const SuggestOptions(
                    suggestType: SuggestType.geo,
                    suggestWords: true,
                    userPosition: Point(latitude: 56.0321, longitude: 38),
                  ),
                );
                resultWithSession.$2.then((value) async{
                  if(value != null){
                    final data = await showSearch(context: context, delegate: MySearchDelegate(value.items!));
                    print("bu data $data");
                    if(data != null){
                      SuggestItem suggest = data;
                      setState(() {
                        najotTalim = Point(latitude: suggest.center!.latitude, longitude: suggest.center!.longitude);
                      });
                    }
                  }
                });
              }

            },child: Icon(Icons.search),)
          ),
        ),
        actions: [
          IconButton(onPressed: () async{
            final res = await mapController.getUserCameraPosition();
            mapController.moveCamera(
              CameraUpdate.zoomIn(),
            );
          }, icon: Icon(Icons.add_circle_outlined)),
          IconButton(onPressed: () async{
            final res = await mapController.getUserCameraPosition();
            mapController.moveCamera(
              CameraUpdate.zoomOut(),
            );
          }, icon: Icon(Icons.remove_circle)),
        ],
      ),
      body: isLoading ? Center(child: CircularProgressIndicator(color: Colors.red,),) : Stack(
        children: [

          YandexMap(
              onMapCreated: onMapCreated,
              onCameraPositionChanged: onCameraPositionChanged,
              mapType: MapType.map,
              mapObjects: [
                PlacemarkMapObject(
                  mapId: const MapObjectId("najotTalim"),
                  point: najotTalim,
                  icon: PlacemarkIcon.single(
                    PlacemarkIconStyle(
                      scale: 0.25,
                      image: BitmapDescriptor.fromAssetImage(
                        "assets/location.png",
                      ),
                    ),
                  ),
                ),
                PlacemarkMapObject(
                  mapId: const MapObjectId("myCurrentLocation"),
                  point: myCurrentLocation ?? najotTalim,
                  icon: PlacemarkIcon.single(
                    PlacemarkIconStyle(
                      scale: 0.25,
                      image: BitmapDescriptor.fromAssetImage(
                        "assets/add_location.png",
                      ),
                    ),
                  ),
                ),



                ...?polylines,

                if(points.length >= 1)
                  PlacemarkMapObject(mapId: MapObjectId("from"), point: points[0],icon: PlacemarkIcon.single(PlacemarkIconStyle(scale: 0.25,image: BitmapDescriptor.fromAssetImage("assets/add_location.png")))),

                if(points.length == 2)
                  PlacemarkMapObject(mapId: MapObjectId("to"), point: points[1],icon: PlacemarkIcon.single(PlacemarkIconStyle(scale: 0.25,image: BitmapDescriptor.fromAssetImage("assets/add_location.png"))))

              ]
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startDocked,
      floatingActionButton: points.length != 2? FloatingActionButton(
        onPressed: (){
          setState(() {
            points.add(myCurrentLocation);
          });
        },
        child: Icon(Icons.add),
      ) : FloatingActionButton(onPressed: (){
        setState(() {
          points = [];
          polylines = [];
        });
      },child: Icon(Icons.cancel,color: Colors.red,),)
    );
  }
}

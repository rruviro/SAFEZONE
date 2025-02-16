// ignore_for_file: unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:safezone/backend/bloc/dangerzoneBloc/dangerzone_bloc.dart';
import 'package:safezone/backend/bloc/dangerzoneBloc/dangerzone_event.dart';
import 'package:safezone/backend/bloc/mapBloc/map_bloc.dart';
import 'package:safezone/backend/bloc/mapBloc/map_state.dart';
import 'package:safezone/backend/services/first_run_service.dart';
import 'package:safezone/frontend/utils/marker_utils.dart';
import 'package:safezone/frontend/widgets/dialogs/dialogs.dart';
import 'package:safezone/resources/schema/colors.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class Map extends StatefulWidget {
  // ignore: non_constant_identifier_names
  final String UserToken;

  // ignore: non_constant_identifier_names
  const Map({super.key, required this.UserToken});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> with TickerProviderStateMixin {
  Set<Marker> markers = {};
  Set<Circle> circles = {};
  static const LatLng sourceLocation = LatLng(16.0471, 120.3425);

  final Completer<GoogleMapController> _mapController = Completer();
  final GlobalKey _searchKey = GlobalKey();
  // final GlobalKey _sosKey = GlobalKey();
  final GlobalKey _circleKey = GlobalKey();
  final GlobalKey _reportKey = GlobalKey();
  final GlobalKey _safeKey = GlobalKey();

  bool _showMarkers = true;
  bool _showOptions = false;

  BitmapDescriptor? customMarker;
  BitmapDescriptor? customDangerZoneMarker;
  BitmapDescriptor? customSafeZoneMarker;

  MapType _currentMapType = MapType.normal;
  late PageController _pageController;
  GoogleMapController? googleMapController;
  late AnimationController _controller;
  late Animation<Offset> _hintAnimation;
  late Animation<Color?> _hintColorAnimation;
  late FocusNode _focusNode;
  late AnimationController _controllerFade;
  late Animation<Color?> _colorAnimation;
  late TextEditingController _textEditingController;
  late AnimationController _mapCategoryHint;
  // bool _isFadedOut = false;

  final List<String> hints = [
    'Barangay',
    'Hospial',
    'Police Station',
    'Municipal',
  ];

  int _currentHintIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<DangerZoneBloc>().add(FetchDangerZones());
    _fetchLocation();
    _checkFirstRun();
    _createCustomMarker();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controllerFade = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _mapCategoryHint = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _mapCategoryHint.repeat();

    _hintAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1),
    ).animate(_controller);

    _hintColorAnimation = ColorTween(
      begin: Colors.black.withOpacity(0.5),
      end: const Color.fromARGB(0, 148, 37, 37),
    ).animate(_controller);

    _colorAnimation = ColorTween(
      begin: Colors.black87,
      end: Colors.transparent,
    ).animate(_controllerFade);

    _focusNode = FocusNode();
    _textEditingController = TextEditingController();
    _changeHintText(); // TODO: Fix error

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _textEditingController.text.isEmpty) {
        _controllerFade.forward();
        _controller.forward();
      } else if (!_focusNode.hasFocus && _textEditingController.text.isEmpty) {
        _controller.reverse();
        _controllerFade.reverse();
      }
    });
  }

  Future<void> _createCustomMarker() async {
    try {
      customMarker =
          await MarkerUtils.createCustomMarker(context, widgetPricolor);
      customDangerZoneMarker = await MarkerUtils.resizeMarker(
        'lib/resources/images/dangerzone.png',
        58,
        86,
      );
      customSafeZoneMarker = await MarkerUtils.resizeMarker(
        'lib/resources/images/safezone.png',
        58,
        86,
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error loading markers: $e");
    }
  }

  void getPolyPoints() async {}

  void _changeHintText() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!_focusNode.hasFocus && _textEditingController.text.isEmpty) {
        _controller.forward().then((_) {
          if (mounted) {
            setState(() {
              _currentHintIndex = (_currentHintIndex + 1) % hints.length;
            });
          }
          _controller.reverse().then((_) {
            if (mounted) {
              _changeHintText();
            }
          });
        });
      } else {
        if (mounted) {
          _changeHintText();
        }
      }
    });
  }

  Future<void> _checkFirstRun() async {
    if (await FirstRunService.isFirstRun()) {
      await _createTutorial();
      await FirstRunService.setFirstRunCompleted();
    }
  }

  Future<void> _fetchLocation() async {
    Position position = await getCurrentLocation();

    if (googleMapController != null) {
      googleMapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.0,
        ),
      ));

      setState(() {
        markers.clear();
        markers.add(Marker(
          markerId: const MarkerId("My Location"),
          position: LatLng(position.latitude, position.longitude),
          icon: customMarker!,
          infoWindow: const InfoWindow(title: 'My Location'),
        ));
      });
    }
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition();
    return position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 216, 216, 216),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                if (state is MapLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MapDataLoaded) {
                  markers.clear();
                  circles.clear();
                  for (var dangerZone in state.dangerZones) {
                    markers.add(
                      Marker(
                        markerId: MarkerId(dangerZone.id.toString()),
                        icon:
                            customDangerZoneMarker!, // TODO: fix this null thing bug
                        // icon: customDangerZoneMarker ??
                        //     BitmapDescriptor.defaultMarker,
                        position:
                            LatLng(dangerZone.latitude, dangerZone.longitude),
                        infoWindow: InfoWindow(
                          title: dangerZone.name,
                        ),
                      ),
                    );
                    circles.add(
                      // TODO: add gesture detector thatll show incident reports in that specific zone, gotta mod the BE pa
                      Circle(
                        circleId: CircleId(dangerZone.id.toString()),
                        center:
                            LatLng(dangerZone.latitude, dangerZone.longitude),
                        radius: dangerZone.radius,
                        strokeWidth: 1,
                        strokeColor: Colors.transparent,
                        fillColor: Colors.red.withOpacity(0.1),
                      ),
                    );
                  }
                  for (var safeZone in state.safeZones) {
                    markers.add(
                      Marker(
                        markerId: MarkerId(safeZone.id.toString()),
                        icon: customSafeZoneMarker ??
                            BitmapDescriptor.defaultMarker,
                        position:
                            LatLng(safeZone.latitude!, safeZone.longitude!),
                        infoWindow: InfoWindow(
                          title: safeZone.name,
                          snippet: "${safeZone.radius}",
                        ),
                      ),
                    );
                    circles.add(
                      Circle(
                        circleId: CircleId(safeZone.id.toString()),
                        center: LatLng(safeZone.latitude!, safeZone.longitude!),
                        radius: safeZone.radius!,
                        strokeWidth: 1,
                        strokeColor: Colors.transparent,
                        fillColor: Colors.green.withOpacity(0.1),
                      ),
                    );
                  }
                } else if (state is MapError) {
                  return Center(child: Text(state.message));
                }

                return GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: sourceLocation,
                    zoom: 14.0,
                  ),
                  mapType: _currentMapType,
                  // markers: {
                  //   if (customMarker != null)
                  //     Marker(
                  //       markerId: const MarkerId('source'),
                  //       position: sourceLocation,
                  //       icon: customMarker!,
                  //       infoWindow: const InfoWindow(title: 'Source Location'),
                  //     ),
                  // },
                  // markers: _showMarkers ? markers : {},
                  markers: {
                    Marker(
                      markerId: const MarkerId('source'),
                      position: sourceLocation,
                      icon: customMarker ?? BitmapDescriptor.defaultMarker,
                      infoWindow: const InfoWindow(title: 'Source Location'),
                    ),
                    if (_showMarkers) ...markers,
                  },

                  circles: circles,
                  onMapCreated: (GoogleMapController controller) async {
                    googleMapController = controller;
                    String style = '''
                            [
                              {
                                "featureType": "poi.business",
                                "elementType": "labels",
                                "stylers": [
                                  { "visibility": "off" }
                                ]
                              },
                              {
                                "featureType": "poi",
                                "elementType": "labels.text",
                                "stylers": [
                                  { "visibility": "off" }
                                ]
                              }
                            ]
                            ''';
                    controller.setMapStyle(style);
                    _mapController.complete(controller);

                    _fetchLocation();
                  },
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                );
              },
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  toolbarHeight: 20,
                ),
                PreferredSize(
                  preferredSize: const Size.fromHeight(120.0),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.transparent,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: SizedBox(
                        height: 50,
                        child: Center(
                          child: Container(
                            height: 40,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: TextField(
                                    controller: _textEditingController,
                                    focusNode: _focusNode,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      hintText: '',
                                      hintStyle: const TextStyle(
                                        color: Colors.transparent,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12.0, vertical: 12.0),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        borderSide: const BorderSide(
                                            color: Colors.white),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        borderSide: const BorderSide(
                                            color: Colors.white),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        borderSide: const BorderSide(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 12,
                                  right: 12,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        key: _searchKey,
                                        onTap: () {
                                          FocusScope.of(context)
                                              .requestFocus(_focusNode);
                                        },
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 4),
                                          child: AnimatedBuilder(
                                            animation: _controllerFade,
                                            builder: (context, child) {
                                              return Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Transform.translate(
                                                      offset:
                                                          const Offset(-5, -10),
                                                      child: Container(
                                                        height: 40,
                                                        width: 40,
                                                        alignment:
                                                            Alignment.center,
                                                        color:
                                                            Colors.transparent,
                                                        child: SvgPicture.asset(
                                                          'lib/resources/svg/search.svg',
                                                          color: _colorAnimation
                                                              .value,
                                                          height: 20,
                                                          width: 20,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                    Transform.translate(
                                                        offset:
                                                            const Offset(-5, 0),
                                                        child: Text(
                                                          "Search for near",
                                                          style: TextStyle(
                                                            color:
                                                                _colorAnimation
                                                                    .value,
                                                            fontSize: 13,
                                                          ),
                                                        ))
                                                  ]);
                                            },
                                          ),
                                        ),
                                      ),
                                      SlideTransition(
                                        position: _hintAnimation,
                                        child: AnimatedBuilder(
                                          animation: _hintColorAnimation,
                                          builder: (context, child) {
                                            return GestureDetector(
                                              onTap: () {
                                                FocusScope.of(context)
                                                    .requestFocus(_focusNode);
                                              },
                                              child: Text(
                                                hints[_currentHintIndex],
                                                style: TextStyle(
                                                  color:
                                                      _hintColorAnimation.value,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Positioned(
                                    top: 0,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Container(
                                        height: 40,
                                        width: 40,
                                        alignment: Alignment.center,
                                        color: Colors.transparent,
                                        child: SvgPicture.asset(
                                          'lib/resources/svg/mic.svg',
                                          color: Colors.black87,
                                          height: 22,
                                          width: 22,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Positioned(
              bottom: 100,
              left: 15,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentMapType = _currentMapType == MapType.normal
                            ? MapType.satellite
                            : MapType.normal;
                      });
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _buildButton(Icons.map),
                      ),
                    ),
                  ),
                  SizedBox(width: 10,),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showMarkers = !_showMarkers;
                      });
                    },
                    child: _buildButton(
                        _showMarkers ? Icons.visibility : Icons.visibility_off),
                  ),
                ]
              ),
            ),
            // Positioned(
            //   left: 20,
            //   bottom: 92,
            //   child: GestureDetector(
            //     onTap: () {
            //       setState(() {
            //         _showOptions = !_showOptions;
            //       });
            //     },
            //     child: AnimatedRotation(
            //       turns: _showOptions ? 0.5 : 0, // Rotates the arrow
            //       duration: const Duration(milliseconds: 300),
            //       child: _buildButton(Icons.keyboard_arrow_down),
            //     ),
            //   ),
            // ),
            // Floating buttons
            widget.UserToken == 'guess'
                ? const SizedBox()
                : Positioned(
                    right: 20,
                    bottom: 80,
                    child: SizedBox(
                      width: 60,
                      height: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            key: _circleKey,
                            onTap: () async {
                              context.push('/sos-page');
                              // Position position = await getCurrentLocation();
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey,
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                    "lib/resources/svg/connect.svg",
                                    color: Colors.blue),
                              ),
                            ),
                          ),
                          GestureDetector(
                            key: _reportKey,
                            onTap: () {
                              showCreateReportDialog(context);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey,
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  "lib/resources/svg/dangerzone.svg",
                                  color: widgetPricolor,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            key: _safeKey,
                            onTap: () {
                              showMarkSafeDialog(context);
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey,
                                    blurRadius: 2,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                    "lib/resources/svg/safezone.svg",
                                    color: Colors.green),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  _createTutorial() {
    final targets = [
      TargetFocus(
        identify: "Circle",
        keyTarget: _circleKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add and see people in your circle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This allows you to stay connected and ensure their safety.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Report",
        keyTarget: _reportKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report any incidents or unsafe situations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps warn others and ensures authorities are informed.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Safe",
        keyTarget: _safeKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If you feel safe in a location, mark it as safe.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps others find safe places nearby when they are in danger.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Search",
        keyTarget: _searchKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Text(
                  'Search for nearby locations.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find safe zones, landmarks, and important places quickly.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    final tutorial = TutorialCoachMark(targets: targets);

    Future.delayed(const Duration(milliseconds: 500), () {
      tutorial.show(context: context);
    });
  }
}

Widget _buildButton(IconData icon) {
  return Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(10), // Square shape with rounded corners
      boxShadow: const [
        BoxShadow(
          color: Colors.grey,
          blurRadius: 2,
          offset: Offset(1, 1),
        ),
      ],
    ),
    child: Center(
      child: Icon(
        icon,
        color: labelFormFieldColor,
      ),
    ),
  );
}

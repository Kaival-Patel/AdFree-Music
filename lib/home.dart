import 'dart:async';
import 'dart:convert';
import 'package:android_notification_listener2/android_notification_listener2.dart';
import 'package:flutter/material.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:silent_ads/SizeConfig.dart';
import 'package:volume/volume.dart';

class home extends StatefulWidget {
  @override
  _homeState createState() => _homeState();
}

class _homeState extends State<home> with WidgetsBindingObserver {
  bool disableAdsSpotify = false,
      disableAdsGaana = false,
      disableAdsJioSaavn = false;
  var permGranted = "granted";
  var permDenied = "denied";
  var permUnknown = "unknown";
  var permProvisional = "provisional";
  AudioManager audioManager;
  int maxVol = 1, currentVol = 1;
  SharedPreferences pref;
  ShowVolumeUI showVolumeUI = ShowVolumeUI.SHOW;
  AndroidNotificationListener _notifications;
  StreamSubscription<NotificationEventV2> _subscription;
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    audioManager = AudioManager.STREAM_MUSIC;
    checkForNotifications();
    initAudioStreamType();
    initSharedPrefs();
    updateVolumes();
    initPlatformState();
  }

  checkForNotifications() async {
    if (await getCheckNotificationPermStatus() == "granted") {
    } else {
      NotificationPermissions.requestNotificationPermissions();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      print("RESUMED!");
      currentVol = await Volume.getVol;
    }
  }

  Future<void> initSharedPrefs() async {
    pref = await SharedPreferences.getInstance();
    if (pref != null) {
      if (pref.getBool("disableAdsSpotify") != null) {
        setState(() {
          disableAdsSpotify = pref.getBool("disableAdsSpotify");
        });
      }
      if (pref.getBool("disableAdsGaana") != null) {
        setState(() {
          disableAdsGaana = pref.getBool("disableAdsGaana");
        });
      }
      if (pref.getBool("disableAdsJioSaavn") != null) {
        setState(() {
          disableAdsJioSaavn = pref.getBool("disableAdsJioSaavn");
        });
      }
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    startListening();
  }

  Future<void> initAudioStreamType() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  updateVolumes() async {
    // get Max Volume
    maxVol = await Volume.getMaxVol;
    // get Current Volume
    currentVol = await Volume.getVol;
  }

  setVol(int i) async {
    await Volume.setVol(i, showVolumeUI: ShowVolumeUI.HIDE);
  }

  void onData(NotificationEventV2 event) {
    print("PACKAGE MESSAGE:");
    print(event.packageMessage.toString());

    print("PACKAGE Name:");
    print(event.packageName.toString());

    print("PACKAGE Text:");
    print(event.packageText.toString());

    //if package name is spotify
    if (event.packageName == "com.spotify.music") {
      if (event.packageText == "Spotify" ||
          event.packageText == "Advertisement") {
        print("AD DETECTED!!!!");
        if (disableAdsSpotify) {
          //down the media volume
          setVol(0);
        }
      } else {
        setVol(currentVol);
      }
    }

    //JIOSAAVN
    if (event.packageName == "com.jio.media.jiobeats") {
      if (event.packageText == "Spotify" ||
          event.packageText == "Advertisement") {
        print("AD DETECTED!!!!");
        if (disableAdsJioSaavn) {
          //down the media volume
          setVol(0);
        }
      } else {
        setVol(currentVol);
      }
    }

    if (event.packageName == "com.gaana") {
      if (event.packageText == "Gaana" ||
          event.packageText == "Advertisement") {
        print("AD DETECTED!!!!");
        if (disableAdsJioSaavn) {
          //down the media volume
          setVol(0);
        }
      } else {
        setVol(currentVol);
      }
    }

    // print('converting package extra to json');
    // var jsonDatax = json.decode(event.packageExtra);
    // print(jsonDatax);
  }

  void startListening() {
    _notifications = new AndroidNotificationListener();
    try {
      _subscription = _notifications.notificationStream.listen(onData);
    } on NotificationExceptionV2 catch (exception) {
      print(exception);
    }
  }

  void stopListening() {
    _subscription.cancel();
  }

  Future<String> getCheckNotificationPermStatus() {
    return NotificationPermissions.getNotificationPermissionStatus()
        .then((status) {
      switch (status) {
        case PermissionStatus.denied:
          return permDenied;
        case PermissionStatus.granted:
          initPlatformState();
          return permGranted;
        case PermissionStatus.unknown:
          return permUnknown;
        case PermissionStatus.provisional:
          return permProvisional;
        default:
          return null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
        body: SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 40.0, 10.0, 10.0),
            child: Container(
              height: SizeConfig.safeBlockVertical * 20,
              decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(SizeConfig.safeBlockHorizontal * 5),
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  image: DecorationImage(
                      image: AssetImage("assets/images/spotify_logo.png"),
                      colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(0.1), BlendMode.dstATop)),
                  boxShadow: [
                    BoxShadow(color: Colors.grey[50], offset: Offset(0, 3))
                  ]),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "MUTE ADS ON SPOTIFY",
                      style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.safeBlockHorizontal * 5),
                    ),
                    Switch(
                      value: disableAdsSpotify,
                      onChanged: (val) {
                        setState(() {
                          pref.setBool("disableAdsSpotify", val);
                          disableAdsSpotify = val;
                        });
                      },
                      activeColor: Colors.green[900],
                    )
                  ],
                ),
              ),
            ),
          ),

          //GAANA
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
            child: Container(
              height: SizeConfig.safeBlockVertical * 20,
              decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(SizeConfig.safeBlockHorizontal * 5),
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  image: DecorationImage(
                      image: AssetImage("assets/images/gaana_logo.png"),
                      colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(0.1), BlendMode.dstATop)),
                  boxShadow: [
                    BoxShadow(color: Colors.grey[50], offset: Offset(0, 3))
                  ]),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "MUTE ADS ON GAANA",
                      style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.safeBlockHorizontal * 5),
                    ),
                    Switch(
                      value: disableAdsGaana,
                      onChanged: (val) {
                        setState(() {
                          pref.setBool("disableAdsGaana", val);
                          disableAdsGaana = val;
                        });
                      },
                      activeColor: Colors.orange[900],
                    )
                  ],
                ),
              ),
            ),
          ),

          //jiosaavn
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
            child: Container(
              height: SizeConfig.safeBlockVertical * 20,
              decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(SizeConfig.safeBlockHorizontal * 5),
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  image: DecorationImage(
                      image: AssetImage("assets/images/jiosaavn_logo.png"),
                      colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(0.1), BlendMode.dstATop)),
                  boxShadow: [
                    BoxShadow(color: Colors.grey[50], offset: Offset(0, 3))
                  ]),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "MUTE ADS ON JIO SAAVN",
                      style: TextStyle(
                          color: Colors.blueGrey[900],
                          fontWeight: FontWeight.bold,
                          fontSize: SizeConfig.safeBlockHorizontal * 5),
                    ),
                    Switch(
                      value: disableAdsJioSaavn,
                      onChanged: (val) {
                        setState(() {
                          pref.setBool("disableAdsJioSaavn", val);
                          disableAdsJioSaavn = val;
                        });
                      },
                      activeColor: Colors.blueGrey[900],
                    )
                  ],
                ),
              ),
            ),
          ),

          Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
              child: FittedBox(
                  child: Column(
                children: [
                  Text("Media Volume"),
                  Slider(
                    value: currentVol / 1.0,
                    inactiveColor: Colors.blue[200],
                    activeColor: Colors.blue[800],
                    //divisions: maxVol,
                    max: maxVol / 1.0,
                    min: 0,
                    onChanged: (double d) {
                      setState(() {
                        setVol(d.toInt());
                        updateVolumes();
                      });
                    },
                  ),
                ],
              ))),
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
            child: Container(
              height: SizeConfig.safeBlockVertical * 5,
              decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(SizeConfig.safeBlockHorizontal * 5),
                  boxShadow: [
                    BoxShadow(color: Colors.grey[50], offset: Offset(0, 3))
                  ]),
              child: Center(
                  child: Text(
                      "Dont go back and close this app! It may stop working!",
                      style: TextStyle(color: Colors.red))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 1.0, 10.0, 1.0),
            child: Container(
              height: SizeConfig.safeBlockVertical * 5,
              child: Center(
                  child: Text("Developed by Kaival Patel",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold))),
            ),
          ),
        ],
      ),
    ));
  }
}

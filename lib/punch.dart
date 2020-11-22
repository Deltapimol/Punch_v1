import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import './login.dart';
import './config.dart';

class Punch extends StatefulWidget {
  final String currentUser;
  Punch({Key key, this.currentUser}) : super(key: key);
  @override
  _PunchState createState() => _PunchState(user: currentUser);
}

class _PunchState extends State<Punch> {
  String user = "";
  _PunchState({this.user});
  int _punchCount = 0;
  SharedPreferences sharedPreferences;
  String spKey = 'timer';
  int constTimer = 0;
  int _timer = 0;
  bool timerActive = false;
  bool time_interval = false;
  Timer _timerClass;
  bool punched = false;
  int extraTime = 0;
  AudioCache _audioCache;

  @override
  void initState() {
    super.initState();
    _audioCache = AudioCache(
        prefix: "audio/",
        fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP));
    checkLoginStatus();
    SharedPreferences.getInstance().then((SharedPreferences sp) {
      sharedPreferences = sp;
      _timer = (sharedPreferences.getInt(spKey)) * 60;
      constTimer = _timer;
      // will be null if never previously saved
      if (_timer == null) {
        _timer = 0;
        persist(_timer); // set an initial value
      }
      setState(() {});
    });
  }

  void persist(int value) {
    setState(() {
      _timer = value;
      constTimer = _timer;
    });
    sharedPreferences?.setInt(spKey, value);
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timerClass = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (_timer == 0) {
            if (punched == false) {
              extraTime += constTimer;
              print("extra time");
              print(extraTime);
            }
            _timer = constTimer;
            _audioCache.play('buzzer.mp3');
            print("TIMEE");
            print(timerActive);
            timerActive = false;
          } else {
            _timer = _timer - 1;
          }
        },
      ),
    );
  }

  int Punch() {
    setState(() {
      print(_punchCount);
      if (timerActive == false) {
        print("TIMEE2");
        print(timerActive);
        punchRequest();
        _punchCount += 1;
        print("PUNCH!");
        timerActive = true;
        startTimer();
        _audioCache.play('timer_reset.mp3');
      }
    });

    return _punchCount;
  }

  checkLoginStatus() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("token") == null) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (BuildContext context) => LoginScreen()),
          (Route<dynamic> route) => false);
    }
  }

  Future<void> punchRequest() async {
    ConfigClass config = ConfigClass();
    int actualTime = 0;
    if (extraTime != 0) {
      actualTime = extraTime + _timer;
      print("ACTUAL TIME");
      print(actualTime);
      setState(() {
        extraTime = 0;
      });
    }
    Map data = {
      "unique_id": sharedPreferences.getString("unique_id"),
      "time_required": (actualTime != 0) ? (actualTime) : (constTimer - _timer)
    };
    String body = json.encode(data);
    // print(body);
    try {
      final response = await http.post(
        config.getBaseUrl() + "/api/v1/controller/punch",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token " + sharedPreferences.getString("token")
        },
        body: body,
      );
      if (response.statusCode == 201) {
        print("PUNCH DONE?");
        setState(() {
          punched = true;
        });
      } else {
        throw Exception('Failed to punch');
      }
    } catch (a, e) {
      print("Exception $a");
      print("Stacktrace $e");
    }
  }

  Future<void> logout() async {
    ConfigClass config = ConfigClass();
    Map data = {"unique_id": sharedPreferences.getString("unique_id")};
    String body = json.encode(data);
    try {
      final response = await http.post(
        config.getBaseUrl() + "/api/v1/account/logout",
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token " + sharedPreferences.getString("token")
        },
        body: body,
      );
      if (response.statusCode == 200) {
        print("LOGOUT DONE?");
      } else {
        throw Exception('Failed to logout');
      }
    } catch (a, e) {
      print("Exception $a");
      print("Stacktrace $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text('User : $user'),
              actions: <Widget>[
                RaisedButton(
                  onPressed: () {
                    logout();
                    sharedPreferences.clear();
                    sharedPreferences.commit();
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (BuildContext context) => LoginScreen()),
                        (Route<dynamic> route) => false);
                  },
                  color: Color.alphaBlend(Colors.red, Colors.white),
                  child: Text(
                    "Logout",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                )
              ],
            ),
            backgroundColor: Colors.deepOrangeAccent,
            body: Builder(builder: (BuildContext context) {
              return Container(
                  alignment: Alignment.topCenter,
                  child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.orange,
                              border: Border.all(
                                  color: Colors.pink[800], // set border color
                                  width: 3.0), // set border width
                              borderRadius: BorderRadius.all(Radius.circular(
                                  10.0)), // set rounded corner radius
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black,
                                    offset: Offset(1, 3))
                              ] // make rounded corner of border
                              ),
                          child: Text(
                            'Timer: $constTimer seconds\n \n Time : $_timer seconds\n',
                            style: TextStyle(fontSize: 25, color: Colors.white),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.orange,
                              border: Border.all(
                                  color: Colors.pink[800], // set border color
                                  width: 3.0), // set border width
                              borderRadius: BorderRadius.all(Radius.circular(
                                  10.0)), // set rounded corner radius
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black,
                                    offset: Offset(1, 3))
                              ] // make rounded corner of border
                              ),
                          child: Text(
                            'Counter : $_punchCount\n',
                            style: TextStyle(fontSize: 25, color: Colors.white),
                          ),
                        ),
                        RawMaterialButton(
                          onPressed: () => Punch(),
                          constraints: BoxConstraints(),
                          elevation: 4.0,
                          fillColor: Colors.white,
                          child: Icon(
                            Icons.add,
                            size: 50.0,
                          ),
                          padding: EdgeInsets.all(15.0),
                          shape: CircleBorder(),
                        ),
                      ]));
            })));
  }
}

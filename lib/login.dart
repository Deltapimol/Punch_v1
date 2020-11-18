import 'dart:async';
import 'dart:convert';
import 'package:Punch_v1/config.dart';
import 'package:Punch_v1/models.dart';
import 'package:Punch_v1/punch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _scanBarcode = 'Unknown';
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          "#ff6666", "Cancel", true, ScanMode.QR);
      print("INSIDE SCANNER" + barcodeScanRes);
      fetchToken(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });
  }

  Future<Login> fetchToken(String _scanBarcode) async {
    String uniqueId = _scanBarcode;
    Map data = {"unique_id": uniqueId};
    String body = json.encode(data);
    print("BODY " + body);
    print("HEELLO from fetch token " + _scanBarcode + " " + uniqueId);
    ConfigClass config = ConfigClass();
    print("URL " + config.getBaseUrl() + "/api/v1/account/login");
    final response = await http.post(
      config.getBaseUrl() + "/api/v1/account/login",
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      print('TOKEN get??' + response.body);
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      var jsonResponse = json.decode(response.body);
      sharedPreferences.setString("token", jsonResponse['token']);
      sharedPreferences.setString("unique_id", jsonResponse['unique_id']);
      String user =
          jsonResponse['first_name'] + " " + jsonResponse['last_name'];
      print('TOKEN get??' +
          jsonResponse['token'] +
          " " +
          jsonResponse['unique_id']);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                  // use container to change width and height
                  height: 100,
                  width: 300,
                  child: Column(children: <Widget>[
                    Stack(
                      alignment: FractionalOffset.center,
                      children: <Widget>[
                        new CircularProgressIndicator(
                          backgroundColor: Colors.red,
                        ),
                      ],
                    ),
                    new Text(
                      "\nLogging In",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )
                  ])));
        },
      );
      new Future.delayed(new Duration(seconds: 3), () {
        Navigator.pop(context); //pop dialog
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (BuildContext context) => Punch(currentUser: user)),
            (Route<dynamic> route) => false);
      });
    } else {
      print('TOKEN no');
      _loginFailed();
      throw Exception('Failed to login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: const Text('Login Page'),
              centerTitle: true,
            ),
            body: Builder(builder: (BuildContext context) {
              return Container(
                  alignment: Alignment.center,
                  child: Flex(
                      direction: Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RaisedButton(
                            autofocus: true,
                            color: Color.alphaBlend(
                                Colors.lightGreen, Colors.lightGreen),
                            onPressed: () => scanQR(),
                            child:
                                Text("Login", style: TextStyle(fontSize: 20)),
                            padding: new EdgeInsets.fromLTRB(30, 20, 30, 20),
                            elevation: 10),
                        //Text('Scan result : $_scanBarcode\n',
                        // style: TextStyle(fontSize: 20))
                      ]));
            })));
  }

  Future<void> _loginFailed() async {
    print("##### IN LOGIN FAILED!");
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: new Text('Could not login. Try again.'),
      duration: new Duration(seconds: 5),
    ));
    throw 'Could not login.';
  }
}

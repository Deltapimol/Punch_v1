import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigClass {
  String _baseUrl =
      "http://ec2-15-206-151-112.ap-south-1.compute.amazonaws.com";
  String _token;
  String _deviceIdentity = "";
  String _currentUser;
  final DeviceInfoPlugin _deviceInfoPlugin = new DeviceInfoPlugin();
  getBaseUrl() {
    print("IN CONFIG get!!!");
    return _baseUrl;
  }

  setCurrentUser(String user) {
    this._currentUser = user;
  }

  getCurrentUser() {
    return _currentUser;
  }

  setToken(String token) {
    this._token = token;
  }

  getToken() {
    return _token;
  }

  Future<String> _getDeviceIdentity() async {
    if (_deviceIdentity == '') {
      try {
        if (Platform.isAndroid) {
          AndroidDeviceInfo info = await _deviceInfoPlugin.androidInfo;
          _deviceIdentity = "${info.device}-${info.id}";
        } else if (Platform.isIOS) {
          IosDeviceInfo info = await _deviceInfoPlugin.iosInfo;
          _deviceIdentity = "${info.model}-${info.identifierForVendor}";
        }
      } on PlatformException {
        _deviceIdentity = "unknown";
      }
    }

    return _deviceIdentity;
  }
}

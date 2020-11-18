import 'package:flutter/foundation.dart';

class Login {
  final String uniqueId;
  final String token;

  Login({this.uniqueId, this.token});

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(uniqueId: json['uniqueId'], token: json['token']);
  }
}

class User {
  final String firstName;
  final String lastName;
  final String uniqueId;
  final String token;

  User({this.firstName, this.lastName, this.uniqueId, this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        firstName: json['firstName'],
        lastName: json['lastName'],
        uniqueId: json['uniqueId'],
        token: json['token']);
  }
}

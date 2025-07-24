import 'dart:convert';
import 'package:flutter/material.dart';

class SensorData {
  final int id;
  String name;
  double value;
  String unit;

  SensorData({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
  });

  void update({required String name, required double value, required String unit}) {
    this.name = name;
    this.value = value;
    this.unit = unit;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'id': id};

    // Only include name if it's not "NULL"
    if (name != "NULL") {
      json['name'] = name;
    }

    // Only include value if it's not negative
    if (value >= 0) {
      json['value'] = value;
    }

    // Only include unit if it's not "NULL"
    if (unit != "NULL") {
      json['unit'] = unit;
    }
    return json;
  }

  @override
  String toString() => jsonEncode(toJson());
}
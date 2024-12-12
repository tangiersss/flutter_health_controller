import 'dart:io';
import 'package:flutter/services.dart';

class BluetoothService {
  static const androidChannel = MethodChannel('com.example.bluetooth');
  static const iosChannel = MethodChannel('com.example.bluetooth.ios');

  static MethodChannel get platformChannel {
    if (Platform.isAndroid) {
      return androidChannel;
    } else if (Platform.isIOS) {
      return iosChannel;
    }
    throw UnsupportedError('Unsupported platform');
  }

  Future<String?> connectToDevice() async {
    try {
      return await platformChannel.invokeMethod<String>('connectToDevice');
    } on PlatformException catch (e) {
      throw Exception('Failed to connect: ${e.message}');
    }
  }

  Future<bool> checkBluetoothConnection() async {
    try {
      final result =
          await platformChannel.invokeMethod<bool>('checkBluetoothConnection');
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to check connection: ${e.message}');
    }
  }
}

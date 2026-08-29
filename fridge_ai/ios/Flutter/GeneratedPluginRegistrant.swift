//
// Generated file. Do not edit.
//
// This file is normally regenerated automatically by the Flutter tool
// (via `flutter pub get` / CocoaPods) to match the plugins declared in
// pubspec.yaml. It is checked into version control here because, as of
// Flutter 3.47.2, the automatic generation of this specific file is
// unreliable when combined with the new UIScene app-lifecycle migration:
// the build's "Run Script" phase sometimes reports the file as already
// up-to-date without ever writing it, producing:
//   "error opening input file '.../ios/Flutter/GeneratedPluginRegistrant.swift'"
//
// If you add, remove, or upgrade a plugin with iOS native code, update the
// list below to match. You can always regenerate a fresh reference copy by
// temporarily deleting this file and running `flutter build ios` locally
// with a non-broken Flutter version, or by running `pod install` and
// checking Xcode's build log for the plugins list.

import Flutter
import Foundation

import camera_avfoundation
import image_picker_ios
import path_provider_foundation
import permission_handler_apple
import shared_preferences_foundation
import sqflite_darwin

@objc class GeneratedPluginRegistrant: NSObject {
  static func register(with registry: FlutterPluginRegistry) {
    CameraPlugin.register(with: registry.registrar(forPlugin: "CameraPlugin"))
    FLTImagePickerPlugin.register(with: registry.registrar(forPlugin: "FLTImagePickerPlugin"))
    PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
    PermissionHandlerPlugin.register(with: registry.registrar(forPlugin: "PermissionHandlerPlugin"))
    SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
    SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  }
}

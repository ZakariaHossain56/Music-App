// import 'package:permission_handler/permission_handler.dart';

// Future<bool> requestStoragePermission() async {
//   final storageStatus = await Permission.storage.request();
//   final audioStatus = await Permission.audio.request();

//   if (storageStatus.isGranted && audioStatus.isGranted) {
//     return true;
//   }

//   // Check for permanently denied permissions
//   if (storageStatus.isPermanentlyDenied || audioStatus.isPermanentlyDenied) {
//     await openAppSettings(); // Guides the user to app settings
//   }

//   return false;
// }


import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  await Permission.audio.request();
  await Permission.storage.request();
}
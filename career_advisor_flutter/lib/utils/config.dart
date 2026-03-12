import 'dart:io';

class AppConfig {
  // Backend base URL
  // For Android emulator, use: http://10.0.2.2:8080
  // For iOS simulator, use: http://localhost:8080
  // For physical devices, use your computer's IP: http://192.168.x.x:8080
  
  // TODO: Update this IP to your computer's local IP address when running on physical device
  static const String _physicalDeviceIp = '172.20.10.2'; // Updated automatically

  static String get baseUrl {
    if (Platform.isAndroid) {
      // Return physical IP for physical device testing
      // Uncomment the line below to switch back to emulator specific address if needed
      // return 'http://10.0.2.2:8080'; 
      return 'http://$_physicalDeviceIp:8080';
    } else if (Platform.isIOS) {
      // iOS simulator can use localhost
      return 'http://localhost:8080';
    } else {
      // Web, Windows, Linux, macOS
      return 'http://localhost:8080';
    }
  }
}

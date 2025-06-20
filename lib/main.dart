import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'blocs/duplicate_finder_bloc.dart';
import 'services/file_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseService.instance.database;
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DupFile Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: BlocProvider(
        create: (context) => DuplicateFinderBloc(
          fileService: FileService(),
          databaseService: DatabaseService.instance,
        ),
        child: PermissionWrapper(),
      ),
    );
  }
}

class PermissionWrapper extends StatefulWidget {
  @override
  _PermissionWrapperState createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _permissionsGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      // Check if permissions are already granted
      bool hasPermissions = await _hasRequiredPermissions();
      
      if (hasPermissions) {
        setState(() {
          _permissionsGranted = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking permissions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _hasRequiredPermissions() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      // Check storage permissions
      var storageStatus = await Permission.storage.status;
      var manageStorageStatus = await Permission.manageExternalStorage.status;
      
      return storageStatus.isGranted || manageStorageStatus.isGranted;
    }
    return true; // For other platforms, assume permissions are granted
  }

  Future<void> _requestPermissions() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Request storage permissions
        Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.manageExternalStorage,
        ].request();

        bool granted = statuses[Permission.storage]?.isGranted == true ||
                      statuses[Permission.manageExternalStorage]?.isGranted == true;

        if (!granted) {
          // Show dialog to open app settings
          _showPermissionDialog();
        } else {
          setState(() {
            _permissionsGranted = true;
          });
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      _showErrorDialog('Failed to request permissions: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Storage Permission Required'),
          content: Text(
            'This app needs storage permission to scan for duplicate files. '
            'Please grant storage permission in the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
                // Recheck permissions after returning from settings
                await Future.delayed(Duration(seconds: 1));
                _checkPermissions();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking permissions...'),
            ],
          ),
        ),
      );
    }

    if (!_permissionsGranted) {
      return Scaffold(
        appBar: AppBar(
          title: Text('DupFile Finder'),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 24),
                Text(
                  'Storage Permission Required',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'To find duplicate files, this app needs permission to access your device storage.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: Icon(Icons.security),
                  label: Text('Grant Permission'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return HomeScreen();
  }
}
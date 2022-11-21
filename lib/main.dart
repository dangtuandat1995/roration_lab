import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

extension NativeDeviceOrientationEx on NativeDeviceOrientation {
  void rotate() {
    switch (this) {
      case NativeDeviceOrientation.portraitUp:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        break;
      case NativeDeviceOrientation.landscapeLeft:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
        ]);
        break;
      case NativeDeviceOrientation.landscapeRight:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
        ]);
        break;
      default:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        break;
    }
  }

  bool get isLandscape {
    switch (this) {
      case NativeDeviceOrientation.landscapeLeft:
      case NativeDeviceOrientation.landscapeRight:
        return true;
      default:
        return false;
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFullscreen = false;
  bool _isLandscapeRight = false;
  bool _fullscreenTracker = false;

  final _orientationStream = NativeDeviceOrientationCommunicator()
      .onOrientationChanged(useSensor: true)
      .distinct();

  static const platform = MethodChannel('android_auto_rotate_setting');

  @override
  void initState() {
    super.initState();
    _orientationStream.listen((orientation) async {
      _isLandscapeRight = orientation == NativeDeviceOrientation.landscapeRight;

      try {
        final bool androidIsAutoRotate = await platform.invokeMethod(
          'getAndroidAutoRotateSetting',
        );
        if (androidIsAutoRotate) {
          if (_isFullscreen == _fullscreenTracker) {
            orientation.rotate();
          } else {
            _isFullscreen = _fullscreenTracker;
          }
        } else {
          if (_isFullscreen) {
            if (orientation == NativeDeviceOrientation.landscapeRight) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeRight,
              ]);
            } else if (orientation == NativeDeviceOrientation.landscapeLeft) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
              ]);
            }
          }
        }
      } catch (e) {
        debugPrint('error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Material App Bar'),
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            _isFullscreen = orientation == Orientation.landscape;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _isFullscreen = !_isFullscreen;
                  _fullscreenTracker = _isFullscreen;
                });

                if (!_isFullscreen) {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                  ]);
                } else {
                  if (_isLandscapeRight) {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeRight,
                    ]);
                  } else {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.landscapeLeft,
                    ]);
                  }
                }
              },
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) {
                    return AnimatedOpacity(
                      opacity: animation.value,
                      duration: Duration.zero,
                      child: child,
                    );
                  },
                  child: _isFullscreen
                      ? const Icon(
                          Icons.fullscreen_exit,
                          color: Colors.black,
                        )
                      : const Icon(
                          Icons.fullscreen,
                          color: Colors.black,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

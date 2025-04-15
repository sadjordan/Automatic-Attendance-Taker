import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> with WidgetsBindingObserver {
  Uri? _url;

  final MobileScannerController controller = MobileScannerController(
      // required options for the scanner
    );
  StreamSubscription<Object?>? _subscription;

  @override
  void initState() {
    super.initState();
    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    // Start listening to the barcode events.
    _subscription = controller.barcodes.listen(_handleqr);

    // Finally, start the scanner itself.
    unawaited(controller.start());
  }

  Future<void> _handleqr(BarcodeCapture barcodeCapture) async {
    controller.stop();
    String? stuff;

    for (final barcode in barcodeCapture.barcodes) {
      stuff = barcode.rawValue;
      print('Barcode found: ${barcode.rawValue}');
      if (barcode.rawValue != null) {
        _url = Uri.parse(barcode.rawValue!);
      }
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code Detected! $stuff'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('A QR code was detected!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Yay!'),
              onPressed: () {
                _launchUrl();
                controller.start();
                Navigator.of(context).pop();
              },)
          ]
        );
      }
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) {
      return;
    }
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = controller.barcodes.listen(_handleqr);

        unawaited(controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(controller.stop());
    }
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
    await controller.dispose();
  }

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url!)) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleqr,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Expanded(child: Center(child: _buildBarcode(_barcode))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';

// class Camera extends StatefulWidget {
//   const Camera({super.key});

//   @override
//   State<Camera> createState() => _CameraState();
// }

// class _CameraState extends State<Camera> {
//   late CameraController controller;
//   late List<CameraDescription> _cameras;

//   @override
//   void initState() {
//     super.initState();
//     _initCamera();
//   }

//   Future<void> _initCamera() async {
//     WidgetsFlutterBinding.ensureInitialized();

//     try {
//       _cameras = await availableCameras();
//       if (_cameras.isNotEmpty) {
//         controller = CameraController(
//           _cameras[0],
//           ResolutionPreset.high,
//         );
//         await controller.initialize();
//         setState(() {});
//       } else {
//         print('No cameras available');
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!controller.value.isInitialized) {
//     return Container();
//     }
//     return MaterialApp(
//       home: CameraPreview(controller)
//     );
//   }
// }
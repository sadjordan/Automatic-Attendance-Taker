import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

import 'package:tragedy/pages/ijustwanttobehappy.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:url_launcher/url_launcher.dart';

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> with WidgetsBindingObserver {
  Uri? _url;
  double _current_zoom = 0.00;
  bool lock = false;
  // final GlobalKey webViewKey = GlobalKey();
  // InAppWebViewController? webViewController;

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
    lock = true;

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
                print("yes 1");
                // _launchUrl();
                // _url = Uri.parse("https://osc.mmu.edu.my/psc/csprd/EMPLOYEE/SA/c/N_PUBLIC.N_CLASS_QRSTUD_ATT.GBL?&GUID=0b5af445-16eb-447b-bc17-b635ce68303f&KEYWORD=KMNOSDSK");
                Navigator.of(context).pop(); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Home(link: _url)),
                );
                print("yes 2");
                lock = false;
                controller.start();
                // Navigator.of(context).pop();
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
    // InAppWebView(
    //   key: webViewKey,
    //   initialUrlRequest: 
    //     URLRequest(url: _url != null ? WebUri.uri(_url!) : null),
    // );

    // if (!await launchUrl(_url!)) {
    //   throw Exception('Could not launch $_url');
    // }
    print("what");

    _url = Uri.parse("https://osc.mmu.edu.my/psc/csprd/EMPLOYEE/SA/c/N_PUBLIC.N_CLASS_QRSTUD_ATT.GBL?&GUID=0b5af445-16eb-447b-bc17-b635ce68303f&KEYWORD=KMNOSDSK");
    
    print("why");
    print("Navigating to Home with URL: $_url");
     MaterialPageRoute(builder: (context) {
        print("Navigating to Home with URL: $_url");
        return Home(link: _url);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (barcodeCapture) {
              if (!lock) {
                _handleqr(barcodeCapture);
              }
            },
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
                  Text(
                    'Zoom: ${_current_zoom.toStringAsFixed(4)}x',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Slider(value: _current_zoom,
                    min: 0.00,
                    max: 1.00,
                    onChanged: (double value) {
                    setState(() {
                      _current_zoom = value;
                      controller.setZoomScale(_current_zoom);
                    });
                  })
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
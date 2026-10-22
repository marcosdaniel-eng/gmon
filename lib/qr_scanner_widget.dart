import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerWidget extends StatefulWidget {
  final Function(String) onDetect;

  const QrScannerWidget({super.key, required this.onDetect});

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();

    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
//Diseño de camara
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 190,
      child: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final codigo = barcode.rawValue;

          if (codigo != null && codigo.isNotEmpty) {
            widget.onDetect(codigo);
          }
        },
      ),
    );
  }
}
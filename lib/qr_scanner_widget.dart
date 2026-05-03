import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerWidget extends StatefulWidget {
  final Function(String) onDetect;

  const QrScannerWidget({
    super.key,
    required this.onDetect,
  });

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _procesarCodigo(String codigo) async {
    if (isProcessing) return;

    isProcessing = true;
    widget.onDetect(codigo);

    await Future.delayed(const Duration(seconds: 100));
    isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green, width: 3),
      ),
      clipBehavior: Clip.hardEdge,
      child: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          final barcode = capture.barcodes.firstOrNull;
          final codigo = barcode?.rawValue;

          if (codigo != null && codigo.isNotEmpty) {
            _procesarCodigo(codigo);
          }
        },
      ),
    );
  }
}
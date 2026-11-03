import 'dart:async';

import 'package:air_reply/core/theme/app_theme.dart';
import 'package:air_reply/demo/demo_mode.dart';
import 'package:air_reply/features/pairing/presentation/pairing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// A camera that fails its first [failures] starts with [error], then works.
class FakeCamera extends MobileScannerPlatform {
  FakeCamera({this.failures = 1, this.error = MobileScannerErrorCode.genericError});

  int failures;
  final MobileScannerErrorCode error;
  int starts = 0;
  final _barcodes = StreamController<BarcodeCapture?>.broadcast();

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.expand(key: ValueKey('camera'));

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    starts++;
    if (failures > 0) {
      failures--;
      throw MobileScannerException(errorCode: error);
    }
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(720, 1280),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}

Future<FakeCamera> openPairing(WidgetTester tester, FakeCamera camera) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  MobileScannerPlatform.instance = camera;
  tester.view
    ..physicalSize = const Size(400, 1000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: demoOverrides('receiver'),
      child: MaterialApp(theme: AppTheme.light(), home: const PairingScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return camera;
}

Future<void> returnToApp(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  await tester.pump();
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a camera that did not start the first time starts when the app comes back', (tester) async {
    final camera = await openPairing(tester, FakeCamera());
    expect(camera.starts, 1);
    expect(find.text('The camera did not start.'), findsOneWidget);

    // the permission dialog closing returns to the app: the scanner starts again, without leaving the screen
    await returnToApp(tester);
    expect(camera.starts, 2);
    expect(find.byKey(const ValueKey('camera')), findsOneWidget);
    expect(find.text('The camera did not start.'), findsNothing);
  });

  testWidgets('refused camera access is not asked for again on return, only from Try again', (tester) async {
    final camera = await openPairing(tester, FakeCamera(error: MobileScannerErrorCode.permissionDenied));
    expect(find.textContaining('needs the camera to scan'), findsOneWidget);

    await returnToApp(tester);
    expect(camera.starts, 1);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    expect(find.byKey(const ValueKey('camera')), findsOneWidget);
  });
}

// `flutter_scene`'s `Scene()` constructor requires the Impeller/Flutter GPU
// backend, which the `flutter_test` harness doesn't provide — it throws
// synchronously outside a real renderer. That makes `OrbitPitch` (and
// anything that embeds it, like `GameScreen`) untestable here; verified
// manually via `flutter run -d chrome` instead. What *is* tested below: the
// pure camera math (no GPU touched) and the stats panel in isolation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'package:flutter_lineup/engine/orbit_camera.dart';
import 'package:flutter_lineup/models/match_data.dart';
import 'package:flutter_lineup/widgets/player_analysis_card.dart';

void main() {
  group('OrbitCamera', () {
    test('orbit shifts yaw and clamps pitch', () {
      final camera = OrbitCamera();
      camera.orbit(const Offset(100, 0));
      expect(camera.yaw, closeTo(-0.6, 1e-9));

      for (var i = 0; i < 500; i++) {
        camera.orbit(const Offset(0, 1000));
      }
      expect(camera.pitch, OrbitCamera.minPitch);

      for (var i = 0; i < 500; i++) {
        camera.orbit(const Offset(0, -1000));
      }
      expect(camera.pitch, OrbitCamera.maxPitch);
    });

    test('zoomBy clamps distance to the allowed range', () {
      final camera = OrbitCamera();
      for (var i = 0; i < 50; i++) {
        camera.zoomBy(0.5);
      }
      expect(camera.distance, OrbitCamera.minDistance);

      for (var i = 0; i < 50; i++) {
        camera.zoomBy(2.0);
      }
      expect(camera.distance, OrbitCamera.maxDistance);
    });

    test('eye sits distance away from the target', () {
      final camera = OrbitCamera(distance: 90);
      final offset = camera.eye - camera.target;
      // vector_math's Vector3 is backed by Float32List, so expect
      // float32-level precision, not double precision.
      expect(offset.length, closeTo(90, 1e-4));
    });

    test('screenToGround lands on the y = 0 plane', () {
      final camera = OrbitCamera(yaw: 0, pitch: 0.6, distance: 100);
      const viewport = Size(800, 600);
      final ground = camera.screenToGround(
        const Offset(400, 300),
        viewport,
      );
      expect(ground, isNotNull);
      expect(ground!.y, closeTo(0, 1e-6));
    });

    test(
      'isViewObstructed flags a stand footprint, clears the open margin '
      'and backing off',
      () {
        // At minPitch/minDistance the eye sits ~55 units out and ~3 units
        // up — inside a stand's [43, 95.5] footprint band, below the roof.
        final camera = OrbitCamera(
          yaw: 0,
          pitch: OrbitCamera.minPitch,
          distance: OrbitCamera.minDistance,
        );
        expect(
          camera.isViewObstructed(
            innerEdge: 43,
            outerEdge: 95.5,
            rooflineHeight: 32,
          ),
          isTrue,
        );

        // Closer than the inner edge is the open margin before any stand —
        // always safe, regardless of height.
        camera.distance = 30;
        expect(
          camera.isViewObstructed(
            innerEdge: 43,
            outerEdge: 95.5,
            rooflineHeight: 32,
          ),
          isFalse,
        );

        // Backing off past the outer edge clears it too, even at the same
        // low pitch.
        camera.distance = OrbitCamera.maxDistance;
        expect(
          camera.isViewObstructed(
            innerEdge: 43,
            outerEdge: 95.5,
            rooflineHeight: 32,
          ),
          isFalse,
        );
      },
    );

    test('toPerspectiveCamera targets the configured point', () {
      final target = vm.Vector3(3, 0, -4);
      final camera = OrbitCamera(target: target);
      final perspective = camera.toPerspectiveCamera();
      expect(perspective.target.x, target.x);
      expect(perspective.target.y, target.y);
      expect(perspective.target.z, target.z);
    });
  });

  group('PlayerAnalysisCard', () {
    testWidgets('shows identity and lets you log a touch', (tester) async {
      final slot = PlayerSlot(
        id: 'CAM',
        fullName: 'Test Player',
        shortName: 'Test',
        shirtNumber: 9,
        nationality: 'Testland',
        x: 0,
        y: 0,
        photoAssetSlug: 'no_such_asset',
      );
      var latest = PlayerStats(touches: 3);
      var closed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PlayerAnalysisCard(
                  slot: slot,
                  stats: latest,
                  onStatsChanged: (s) => setState(() => latest = s),
                  onClose: () => closed = true,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Player'), findsOneWidget);
      final touchesCounter = find
          .ancestor(of: find.text('Touches'), matching: find.byType(Column))
          .first;
      expect(
        find.descendant(of: touchesCounter, matching: find.text('3')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: touchesCounter,
          matching: find.byIcon(Icons.add_rounded),
        ),
      );
      await tester.pump();

      expect(latest.touches, 4);
      expect(closed, isFalse);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:wms_3d/models/warehouse_models.dart';
import 'package:wms_3d/state/toast_controller.dart';
import 'package:wms_3d/state/warehouse_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('block mode (move/rotate whole streets)', () {
    test('moving a selected street to open space updates its origin, and moving back restores it', () async {
      final controller = WarehouseController(toasts: ToastController());
      await controller.switchDataset(DatasetMode.simulated, announce: false);

      controller.toggleEditMode();
      controller.toggleBlockMode();
      controller.toggleRuaSelection(0);

      final street = controller.streets[0];
      final originalX = street.originX;
      final originalZ = street.originZ;

      controller.moveSelectedRuas(1000, 0);
      expect(street.originX, closeTo(originalX + 1000, 1e-9));
      expect(street.originZ, closeTo(originalZ, 1e-9));

      controller.moveSelectedRuas(-1000, 0);
      expect(street.originX, closeTo(originalX, 1e-9));
      expect(street.originZ, closeTo(originalZ, 1e-9));
    });

    test('rotating a selected street in open space flips its orientation', () async {
      final controller = WarehouseController(toasts: ToastController());
      await controller.switchDataset(DatasetMode.simulated, announce: false);

      controller.toggleEditMode();
      controller.toggleBlockMode();
      controller.toggleRuaSelection(0);

      // Move far from every other street first so rotation can't collide.
      controller.moveSelectedRuas(5000, 5000);
      final street = controller.streets[0];
      expect(street.orientation, StreetOrientation.eastWest);

      controller.rotateSelectedRuas();
      expect(street.orientation, StreetOrientation.northSouth);

      controller.rotateSelectedRuas();
      expect(street.orientation, StreetOrientation.eastWest);
    });

    test('moving a selected street onto a heavily-occupied neighbor is blocked by collision', () async {
      final controller = WarehouseController(toasts: ToastController());
      await controller.switchDataset(DatasetMode.real, announce: false);

      controller.toggleEditMode();
      controller.toggleBlockMode();
      controller.toggleRuaSelection(0);

      final moving = controller.streets[0];
      final target = controller.streets[1];
      final originalX = moving.originX;
      final originalZ = moving.originZ;
      final dx = target.originX - moving.originX;
      final dz = target.originZ - moving.originZ;

      controller.moveSelectedRuas(dx, dz);

      // The real dataset's first two streets are densely packed with
      // overlapping (andar, pos) ranges, so landing rua 0 exactly on rua 1
      // must collide — the origin should be rejected and left unchanged.
      expect(moving.originX, originalX);
      expect(moving.originZ, originalZ);
    });

    test('selecting a rua by tapping toggles membership, and leaving edit mode clears the selection', () async {
      final controller = WarehouseController(toasts: ToastController());
      await controller.switchDataset(DatasetMode.simulated, announce: false);

      controller.toggleEditMode();
      controller.toggleBlockMode();

      controller.toggleRuaSelection(0);
      controller.toggleRuaSelection(1);
      expect(controller.selectedRuas, {0, 1});

      controller.toggleRuaSelection(0);
      expect(controller.selectedRuas, {1});

      controller.toggleEditMode(); // leaving edit mode also exits block mode
      expect(controller.blockMode, isFalse);
      expect(controller.selectedRuas, isEmpty);
    });
  });
}

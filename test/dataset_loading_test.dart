import 'package:flutter_test/flutter_test.dart';
import 'package:wms_3d/data/real_dataset_loader.dart';
import 'package:wms_3d/data/simulated_dataset_loader.dart';
import 'package:wms_3d/models/warehouse_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real dataset loads 11 streets and 344 pallets from the asset', () async {
    final dataset = await RealDatasetLoader().load();
    expect(dataset.mode, DatasetMode.real);
    expect(dataset.streets.length, 11);
    expect(dataset.pallets.length, 344);
    expect(dataset.pallets.any((p) => p.produtos.length > 1), isTrue);
  });

  test('simulated dataset generates sector-based streets and pallets', () {
    final dataset = SimulatedDatasetLoader().load();
    expect(dataset.mode, DatasetMode.simulated);
    expect(dataset.streets.length, 4);
    expect(dataset.pallets, isNotEmpty);
    expect(dataset.pallets.every((p) => p.setorEsperado != null), isTrue);
  });
}

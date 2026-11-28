import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';

void main() {
  testWidgets('LayerNamingUtility constants test', (WidgetTester tester) async {
    // Test that layer naming utilities work correctly
    const testMemberName = 'Heavy Vehicle Rest Areas';

    final sourceId = LayerNamingUtility.getPoiMemberSourceId(testMemberName);
    final layerId = LayerNamingUtility.getPoiMemberLayerId(testMemberName);

    expect(sourceId, equals('source-poi-heavy_vehicle_rest_area'));
    expect(layerId, equals('layer-poi-heavy_vehicle_rest_area-symbol'));

    // Test that POI constants are available
    expect(LayerNamingUtility.POI_HVS_INSPECTION, isNotEmpty);
    expect(LayerNamingUtility.POI_ROAD_TRAIN_ASSEMBLY, isNotEmpty);
    expect(LayerNamingUtility.POI_HEAVY_VEHICLE_REST, isNotEmpty);

    // Create a simple test widget to verify Flutter test framework is working
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Text('Test Widget'),
      ),
    ));

    expect(find.text('Test Widget'), findsOneWidget);
  });
}

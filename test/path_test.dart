import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/utils/layer_naming_utilities.dart';

void main() {
  group('LayerNamingUtility Tests', () {
    test('POI layer naming follows convention', () {
      const testMemberName = 'Heavy Vehicle Rest Areas';

      final sourceId = LayerNamingUtility.getPoiMemberSourceId(testMemberName);
      final layerId = LayerNamingUtility.getPoiMemberLayerId(testMemberName);

      expect(sourceId, equals('source-poi-heavy_vehicle_rest_area'));
      expect(layerId, equals('layer-poi-heavy_vehicle_rest_area-symbol'));
    });

    test('POI constants are defined correctly', () {
      expect(LayerNamingUtility.POI_HVS_INSPECTION, equals('hvs_inspection_bays'));
      expect(LayerNamingUtility.POI_ROAD_TRAIN_ASSEMBLY, equals('road_train_assembly_area'));
      expect(LayerNamingUtility.POI_HEAVY_VEHICLE_REST, equals('heavy_vehicle_rest_area'));
    });

    test('getAllPoiLayerIds returns complete list', () {
      final allPoiLayers = LayerNamingUtility.getAllPoiLayerIds();

      expect(allPoiLayers, isNotEmpty);
      expect(allPoiLayers, contains('layer-poi-hvs_inspection_bays-symbol'));
      expect(allPoiLayers, contains('layer-poi-road_train_assembly_area-symbol'));
    });

    test('getAllPoiSourceIds returns complete list', () {
      final allPoiSources = LayerNamingUtility.getAllPoiSourceIds();

      expect(allPoiSources, isNotEmpty);
      expect(allPoiSources, contains('source-poi-hvs_inspection_bays'));
      expect(allPoiSources, contains('source-poi-road_train_assembly_area'));
    });
    test('getAllQueryableLayerIds includes POI layers', () {
      final allQueryableLayers = LayerNamingUtility.getAllQueryableLayerIds();

      expect(allQueryableLayers, isNotEmpty);
      expect(allQueryableLayers, contains('layer-poi-hvs_inspection_bays-symbol'));
      expect(allQueryableLayers, contains('layer-poi-road_train_assembly_area-symbol'));
    });
  });
}

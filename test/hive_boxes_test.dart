import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/hive_boxes.dart';

void main() {
  test('box names keep their persisted literal values', () {
    expect(HiveBoxes.layers, 'layersBox');
    expect(HiveBoxes.settings, 'settingsBox');
    expect(HiveBoxes.showAllLayers, 'showAllLayersBox');
    expect(HiveBoxes.selectedPoiLayer, 'selectedPoiLayerBox');
    expect(HiveBoxes.selectedLayer, 'selectedLayerBox');
    expect(HiveBoxes.markerImages, 'marker_images');
    expect(HiveBoxes.pointsOfInterest, 'pointsOfInterestBox');
    expect(HiveBoxes.roadNetworks, 'roadNetworksBox');
  });

  test('required startup boxes are exactly the bootstrap set', () {
    expect(HiveBoxes.requiredAtStartup, [
      'layersBox',
      'settingsBox',
      'showAllLayersBox',
      'selectedPoiLayerBox',
      'selectedLayerBox',
      'marker_images',
    ]);
  });
}

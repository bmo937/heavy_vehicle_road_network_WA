# Tool: Main Roads schema probe

Read-only research tooling. Not imported by `lib/`; does not touch the production service URL.

Source: `https://gisservices.mainroads.wa.gov.au/arcgis/rest/services/OpenData/HVS_Networks_DataPortal/MapServer`
(not the `HVS_Networks_2_DataPortal` service used by `lib/providers/network_data_service.dart`).

Layers: 78; 29-32; 34-37; 74-77. Attribute-only (`returnGeometry=false`) paginated GET queries, sequential with a short delay.

## Run (live service)

```
flutter pub get
dart run tool/main_roads_schema_probe.dart
```

Options: `--output-report=PATH`, `--output-json=PATH`, `--sample-limit=N` (default 3).

Writes `docs/main_roads_schema_investigation.md` and `tool/output/main_roads_schema_summary.json`.
Exits with code 2 and marks the report INCOMPLETE if any layer fails or pagination is partial.

## Tests (no network)

```
flutter test test/tool/main_roads_schema_probe_test.dart
```

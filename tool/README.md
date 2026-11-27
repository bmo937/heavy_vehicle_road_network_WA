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

# Tool: Main Roads topology probe

Read-only research tooling for layer 78 PHYSICAL geometry topology. Not imported by `lib/`. It builds no `RoadGraph`, snaps no coordinates, creates no junctions and does not interpret `MAX_NETWORK`, network eligibility or restrictions.

Retrieves all layer-78 features with geometry (`where=1=1`, `outFields=*`, `returnGeometry=true`, `outSR=4326`, `f=geojson`), paginated by `OBJECTID`. All pages are merged into one FeatureCollection and parsed with the production `MainRoadsNetworkParser` (so duplicate-GlobalID detection spans all pages). The run is INCOMPLETE (exit code 2, no analysis) if any page fails, pagination is partial, the retrieved count differs from the service's `returnCountOnly` total, or the parser rejects any feature.

## Run (live service)

```
flutter pub get
dart run tool/main_roads_topology_probe.dart
```

Options: `--output-report=PATH`, `--output-json=PATH`. Writes `docs/main_roads_topology_investigation.md` and `tool/output/main_roads_topology_summary.json`.

Cloud: run the manually triggered **Main Roads topology probe** workflow (Actions tab -> Run workflow). Successful COMPLETE runs publish the two result files to `generated/topology-investigation`, so the latest COMPLETE investigation can be read through the GitHub repository API without downloading an Actions artifact. Incomplete or failed runs do not modify that branch. The `main-roads-topology-investigation` artifact is still uploaded for diagnostics, including failed or incomplete runs where files exist. The generated branch contains research output only; it is not production application state.

## Method notes

- Distances in metres use haversine on lon/lat degrees; exact equality (identical doubles) is kept separate from distance buckets.
- Endpoint proximity: grid candidate filter, 10 m search radius.
- Crossings: uniform lon/lat grid -> bounding-box filter -> exact segment intersection (axis-scaling invariant, no tolerance). Crossings are not junctions.

## Tests (no network)

```
flutter test test/tool/main_roads_topology_probe_test.dart
```

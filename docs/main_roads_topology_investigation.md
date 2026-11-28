# Main Roads layer 78 topology investigation

Read-only diagnostic of PHYSICAL geometry topology. Generated 2026-11-28T02:41:17.053117Z.

> Physical geometry topology only. MAX_NETWORK, network eligibility, restrictions and Tandem Drive Network 1 semantics are deliberately not interpreted. No RoadGraph was built, no coordinate was snapped and no feature was merged or removed.

## A. Run status

- **Status: COMPLETE**
- Source: https://gisservices.mainroads.wa.gov.au/arcgis/rest/services/OpenData/HVS_Networks_DataPortal/MapServer/78 (Tandem Drive 1-10 All Networks)
- Query: `where=1=1&outFields=*&returnGeometry=true&outSR=4326&f=geojson (paginated, OBJECTID order)`
- Pages fetched: 11
- Features retrieved: 10025; service-reported count: 10025
- Parsed record count: 10025

## B. Geometry inventory

| Measure | Count |
|---|---|
| Source features (GlobalIDs) | 10025 |
| Line parts (LineString = 1, MultiLineString = one per member line) | 35865 |
| Total vertices | 594231 |
| Distinct exact coordinates | 554507 |
| Source part endpoints (2 per line part) | 71730 |
| Distinct endpoint coordinates | 32128 |
| Closed-loop line parts (first == last) | 5 |

Coordinates are WGS84 longitude/latitude degrees; "exact" means identical doubles, no rounding.

## C. Exact endpoint connectivity

| Measure | Count |
|---|---|
| Endpoints coinciding exactly with an endpoint of a different feature | 40056 |
| Endpoint coordinate groups with one endpoint | 5541 |
| Endpoint coordinate groups with exactly two endpoints | 14909 |
| Endpoint coordinate groups with three or more endpoints | 11678 |
| Endpoint groups spanning more than one feature | 13594 |

Endpoint-count histogram per coordinate group: 1: 5541; 2: 14909; 3: 10363; 4: 1296; 5: 16; 6: 3
(A closed-loop LineString contributes both its endpoints to one group.)

## D. Near-endpoint distances

Great-circle (haversine) metres to the nearest endpoint of a DIFFERENT feature, searched within 10.0 m using a grid candidate filter. Exact equality is a separate class. Nothing is snapped and no tolerance is chosen.

| Bucket | Nearest other endpoint | Nearest non-identical endpoint |
|---|---:|---:|
| exact same coordinate | 40056 | 0 |
| >0 to 0.1 m | 690 | 880 |
| >0.1 to 0.5 m | 1327 | 1590 |
| >0.5 to 1 m | 237 | 272 |
| >1 to 2 m | 124 | 137 |
| >2 to 5 m | 163 | 186 |
| >5 to 10 m | 639 | 897 |
| >10 m | 28494 | 67768 |

"Nearest non-identical" ignores exact partners, so it exposes near-misses even for endpoints that also have an exact partner.

## E. Endpoint / internal-vertex relationships

| Measure | Count |
|---|---|
| Endpoints coinciding exactly with an INTERNAL vertex of another feature | 174 |
| Coordinate groups where that happens | 99 |

## F. Shared internal vertices

| Measure | Count |
|---|---|
| Internal vertex occurrences (total) | 522501 |
| Internal vertex occurrences whose exact coordinate is used by another feature | 137 |
| Coordinate groups where internal vertices of 2+ features meet | 19 |
| Groups where one feature repeats a coordinate at an internal vertex | 5 |

Coordinate groups shared by 2+ features, by kind: endpointsOnly: 13588; endpointAndInternal: 99; internalOnly: 19
By participating feature count: 2: 12735; 3: 927; 4: 44
By distinct ROAD values: 1: 258; 2: 12785; 3: 638; 4: 25
By distinct ROUTE_NE_ID values: 1: 258; 2: 12785; 3: 638; 4: 25

Per-group detail (13706 recorded) is in the JSON output only.

## G. Geometric crossings without shared vertices

Intersections between different features that are not at an exact shared source vertex. A crossing is NOT a junction (grade separation may exist) and none was created. Tests use exact double arithmetic in lon/lat space (axis-scaling invariant); near-misses and near-collinear overlaps are not detected.

| Measure | Count |
|---|---|
| Segments indexed | 558366 |
| Segment pairs a naive comparison would test | 155886015795 |
| Candidate pairs after grid + bounding-box filter | 40380 |
| Unrepresented crossings | 1440 |
| ...of which involve a feature endpoint | 7 |

By kind: proper: 1433; touch: 7
By role of each feature at the intersection: A:segmentInterior / B:segmentInterior: 1433; A:segmentInterior / B:endpoint: 4; A:endpoint / B:segmentInterior: 3
By ROAD / ROUTE_NE_ID relation: different ROAD, different ROUTE_NE_ID: 1434; same ROAD, same ROUTE_NE_ID: 6
Distance from intersection to the nearer feature's own nearest vertex: >0 to 0.1 m: 700; >0.1 to 0.5 m: 162; >0.5 to 1 m: 55; >1 to 2 m: 61; >2 to 5 m: 85; >5 to 10 m: 158; >10 m: 212; 0 m: 7

Detail records: 1440 in the JSON.

## H. Duplicate / reversed geometry

| Measure | Count |
|---|---|
| Duplicate-geometry groups | 0 |
| Exact duplicate pairs | 0 |
| Reversed duplicate pairs | 0 |
| Zero-length consecutive coordinate pairs | 0 |
| Features containing zero-length pairs | 0 |
| Degenerate features (all vertices identical) | 0 |
| Tiny segments (>0 to 1.0 m) | 206 |
| Features containing tiny segments | 143 |

Duplicate pairs by relation: none
Segment length buckets (exact = zero length): exact same coordinate: 0; >0 to 0.1 m: 7; >0.1 to 0.5 m: 61; >0.5 to 1 m: 138; >1 to 2 m: 757; >2 to 5 m: 5644; >5 to 10 m: 51291; >10 m: 500468
Nothing was deduplicated, removed or repaired.

## I. ROUTE_NE_ID / ROAD continuity at shared endpoints

Feature pairs meeting at an exact shared endpoint. Diagnostic only: no turn permission or merge is implied.

| Category | Feature pairs |
|---|---|
| A: same ROAD + same ROUTE_NE_ID | 569 |
| B: same ROAD + different ROUTE_NE_ID | 0 |
| C: different ROAD + same ROUTE_NE_ID | 0 |
| D: different ROAD + different ROUTE_NE_ID | 15089 |

Shared-endpoint groups by the set of categories present: D: 13035; A+D: 315; A: 244

## I.1 Endpoint-to-segment proximity

For endpoints without an exact different-feature endpoint partner, this diagnostic searches for the nearest finite segment belonging to another source feature within 10.0 m. Candidates are diagnostic only: no coordinate was snapped, no feature was split and no junction was created.

| Measure | Count |
|---|---:|
| Eligible endpoints without an exact different-feature endpoint partner | 31674 |
| Endpoints with a foreign-segment candidate within radius | 4004 |
| Endpoints without a foreign-segment candidate within radius | 27670 |

Nearest finite-segment distance: 0 m: 170; >0 to 0.1 m: 1798; >0.1 to 0.5 m: 1105; >0.5 to 1 m: 248; >1 to 2 m: 132; >2 to 5 m: 173; >5 to 10 m: 378; >10 m: 27670

Nearest segment-interior distance: 0 m: 7; >0 to 0.1 m: 1539; >0.1 to 0.5 m: 625; >0.5 to 1 m: 152; >1 to 2 m: 80; >2 to 5 m: 105; >5 to 10 m: 318; >10 m: 28848

Nearest target location: segmentInterior: 2766; segmentStart: 651; segmentEnd: 587; noneWithinRadius: 27670

By ROAD / ROUTE_NE_ID relation: different ROAD, different ROUTE_NE_ID: 3988; same ROAD, same ROUTE_NE_ID: 16

Detail records: 4004 in the JSON.

## J. Topology implications

### CONFIRMED FROM DATA

- 40056 of 71730 endpoints (31674 do not) coincide exactly with an endpoint of another feature.
- 174 endpoints coincide exactly with an internal vertex of another feature (99 coordinate groups).
- 19 coordinate groups join internal vertices of two or more features.
- Of the 31674 endpoints without an exact partner, 2254 have a different-feature endpoint within 1 m, 2378 within 2 m and 3180 within 10 m (nearest-other measure).
- 1440 geometric intersections are not represented by a shared source vertex.
- 0 duplicate/reversed geometry pairs; 0 zero-length vertex pairs; 206 tiny segments.
- Segmentation: the source is NOT uniformly split at shared vertices; at least some features carry an interior vertex that coincides with another feature's vertex or endpoint.

### RECOMMENDATION FOR FUTURE COMPILER

- Treat exact coordinate equality as the only confirmed node identity; do not merge near endpoints without a separate, evidenced decision.
- Plan to split features at shared internal vertices / endpoint-on-vertex contacts so those contacts can become nodes.
- Keep the 1440 unrepresented crossings as non-junctions until inspected; some may be grade separations.
- Missing or unmatched endpoints must not be assumed to be dead ends.

## K. Candidate next milestone

Decision support only; no compiler is implemented here.

- **Endpoint-only topology:** supported as a baseline (40056 endpoints have exact partners), but it leaves 31674 endpoints unconnected.
- **Snapped endpoint topology:** needs further investigation. Candidate tolerances to study (not chosen): 0.1 m, 0.5 m, 1 m, 2 m, 5 m, 10 m; endpoints without an exact partner and within 1 / 2 / 10 m: 2254 / 2378 / 3180.
- **Splitting at shared internal vertices:** indicated by the data.
- **Further geometry investigation:** unrepresented crossings (1440); endpoint near-misses; endpoint-to-segment proximity (measured; see section I.1).

**Cannot be established by this diagnostic:** whether crossings are junctions or grade separations; whether near endpoints are the same node; near-collinear overlaps; whether endpoint-to-segment near-misses represent true junctions (no tolerance is applied); self-crossings within one feature; any eligibility or restriction semantics.

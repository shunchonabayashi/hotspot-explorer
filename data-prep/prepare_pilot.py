"""Prepare a small, auditable Bangladesh pilot. Requires shapely and pyproj.

Run at repository root: python data-prep/prepare_pilot.py
An optional --cache-dir points to previously downloaded flood.csv and wb-bgd.geojson.
The Shiny app itself needs neither Python nor spatial packages.
"""
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from shapely.geometry import shape
from shapely import make_valid
from shapely.ops import transform
from pyproj import Transformer

ROOT = Path(__file__).resolve().parents[1]
FLOOD_URL = 'https://datacatalogfiles.worldbank.org/ddh-published/0066820/DR0095355/adm2_flood_exposure_15cm_1in100.csv'
BOUNDARY_SERVICE = 'https://services.arcgis.com/iQ1dY19aHwbSDYIF/ArcGIS/rest/services/World_Bank_Global_Administrative_Divisions/FeatureServer/3'
BOUNDARY_URL = BOUNDARY_SERVICE + '/query?' + urllib.parse.urlencode({
    'where': "WB_A3='BGD'", 'outFields': 'ADM2CD_c,NAM_0,NAM_1,NAM_2',
    'outSR': 4326, 'f': 'geojson', 'returnGeometry': 'true'})
STAC_URL = 'https://raw.githubusercontent.com/worldbank/DECAT_Space2Stats/main/space2stats_api/src/space2stats_ingest/METADATA/stac/space2stats-collection/flood_exposure_15cm_1in100/flood_exposure_15cm_1in100.json'


def write_csv(path, rows):
    with path.open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cache-dir', type=Path)
    args = parser.parse_args()

    def fetch(filename, url):
        if args.cache_dir and (args.cache_dir / filename).exists():
            return (args.cache_dir / filename).read_bytes()
        return urllib.request.urlopen(url, timeout=120).read()

    flood_bytes = fetch('flood.csv', FLOOD_URL)
    boundary_bytes = fetch('wb-bgd.geojson', BOUNDARY_URL)
    raw_rows = [r for r in csv.DictReader(io.StringIO(flood_bytes.decode('utf-8-sig'))) if r['ISO3'] == 'BGD']
    flood = {r['ADM2CD_c']: r for r in raw_rows}
    boundaries = json.loads(boundary_bytes)['features']
    assert len(flood) == len(raw_rows) == len(boundaries) == 64
    assert {f['properties']['ADM2CD_c'] for f in boundaries} == set(flood)
    project = Transformer.from_crs(4326, 32646, always_xy=True).transform
    repair_ids = [f['properties']['ADM2CD_c'] for f in boundaries if not shape(f['geometry']).is_valid]
    shapes = {f['properties']['ADM2CD_c']: transform(project, make_valid(shape(f['geometry']))) for f in boundaries}
    assert all(g.is_valid for g in shapes.values())
    focus = 'BGD008003'  # Sunamganj; selected for complete national data and substantial exposure.
    # Rook adjacency: an actual shared boundary segment, not just a nearby centroid.
    neighbours = sorted(k for k, g in shapes.items() if k != focus and shapes[focus].boundary.intersection(g.boundary).length > 100)
    assert neighbours == ['BGD003005', 'BGD005003', 'BGD008001', 'BGD008004']
    local_ids = [focus] + neighbours
    out = ROOT / 'app' / 'data'
    out.mkdir(parents=True, exist_ok=True)
    rows = []
    for feature in boundaries:
        p = feature['properties']; code = p['ADM2CD_c']; d = flood[code]
        population = float(d['pop']); exposed = float(d['pop_flood'])
        assert population > 0 and 0 <= exposed <= population
        rows.append({'id': code, 'district': p['NAM_2'], 'division': p['NAM_1'],
                     'population_2020': population, 'exposed_population': exposed,
                     'exposed_share_pct': 100 * exposed / population,
                     'pilot_area': int(code in local_ids), 'default_district': int(code == focus)})
    rows.sort(key=lambda r: r['district'])
    write_csv(out / 'districts.csv', rows)
    write_csv(out / 'source_flood_bgd.csv', raw_rows)

    def geometry_rows(ids, width, height):
        selected = [shapes[k] for k in ids]
        xmin = min(g.bounds[0] for g in selected); ymin = min(g.bounds[1] for g in selected)
        xmax = max(g.bounds[2] for g in selected); ymax = max(g.bounds[3] for g in selected)
        pad = 28
        scale = min((width - 2*pad)/(xmax-xmin), (height-2*pad)/(ymax-ymin))
        xoff = (width - (xmax-xmin)*scale)/2
        yoff = (height - (ymax-ymin)*scale)/2

        def xy(x, y):
            return xoff+(x-xmin)*scale, height-yoff-(y-ymin)*scale

        result = []
        for code in ids:
            # Map-only simplification; adjacency above used the original geometries.
            g = shapes[code].simplify(180, preserve_topology=True)
            polygons = [g] if g.geom_type == 'Polygon' else list(g.geoms)
            paths = []
            for polygon in polygons:
                for ring in [polygon.exterior, *polygon.interiors]:
                    pts = [xy(x, y) for x, y in ring.coords]
                    paths.append('M' + ' L'.join(f'{x:.1f},{y:.1f}' for x, y in pts) + ' Z')
            point = shapes[code].representative_point()
            x, y = xy(point.x, point.y)
            result.append({'id': code, 'path': ' '.join(paths), 'label_x': round(x,1), 'label_y': round(y,1)})
        return result

    write_csv(out / 'local_map.csv', geometry_rows(local_ids, 900, 470))
    write_csv(out / 'country_map.csv', geometry_rows(sorted(shapes), 240, 290))
    provenance = {
        'prepared_utc': datetime.now(timezone.utc).isoformat(), 'country': 'Bangladesh',
        'default_district': 'Sunamganj', 'default_id': focus, 'district_count': 64,
        'pilot_ids': local_ids, 'adjacency': 'Shared boundary segment >100 m in UTM 46N, computed before simplification; Bangladesh neighbours only.',
        'flood_url': FLOOD_URL, 'flood_source_sha256': hashlib.sha256(flood_bytes).hexdigest(),
        'flood_catalog': 'https://datacatalog.worldbank.org/search/dataset/0066820/space2stats-database',
        'flood_metadata': STAC_URL, 'boundary_query_url': BOUNDARY_URL,
        'boundary_source_sha256': hashlib.sha256(boundary_bytes).hexdigest(),
        'geometry_repairs': repair_ids,
        'boundary_catalog': 'https://datacatalog.worldbank.org/search/dataset/0038272/world-bank-official-boundaries',
        'license': 'World Bank Space2Stats and Official Boundaries: CC BY 4.0. Derived map and share calculations by this pilot.',
        'population_year': 2020, 'hazard': 'Modelled flood depth >15 cm, 1-in-100 return period; Fathom v3 / WorldPop.',
        'hazard_reference_year': 'Not specified in the ADM2 CSV; not represented as a 2050 projection or observed event.',
        'processing': 'Joined by ADM2CD_c. District share = 100 * pop_flood / pop. The supplied pop_flood_pct column is retained for audit but not used: district ratios are recalculated from summed counts.',
        'resolution': 'Space2Stats H3 level 6 aggregates (~36 km2 cells); the detailed map is not evidence of equally detailed exposure estimates.',
        'vintage_note': 'June 2025 exposure download matched by district code to the boundary service retrieved for this pilot. Code coverage is verified; exact boundary-vintage equivalence is not established.',
        'not_assessed': ['future climate change', 'market access and service disruption', 'AIIB project coverage', 'investment gaps', 'costs', 'other five pressures']
    }
    (out / 'provenance.json').write_text(json.dumps(provenance, indent=2), encoding='utf-8')
    print('Prepared 64 real district records, 5 pilot polygons, national locator and provenance.')
    print('Neighbours:', [r['district'] for r in rows if r['id'] in neighbours])


if __name__ == '__main__':
    main()

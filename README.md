# Wild Camping Legality Checker API

A Rails API that answers "Can I legally sleep here?" for any GPS coordinate using actual land classification data + legal rules.

## Quick Start

```bash
# Start the containers
docker compose up -d

# Run migrations (first time only)
docker compose exec api bin/rails db:migrate

# Import the GeoJSON data
docker compose exec api rake import:all

# Test the API
curl "http://localhost:3000/check?lat=49.68&lng=13.82"
```

## API Endpoints

### `GET /check?lat=X&lng=Y`

Check if wild camping is allowed at a location.

**Example:**
```bash
curl "http://localhost:3000/check?lat=49.68&lng=13.82"
```

**Response:**
```json
{
  "lat": 49.68,
  "lng": 13.82,
  "country": "CZ",
  "areas": [
    {
      "name": "CHKO Brdy",
      "protect_class": "5",
      "protection_title": "Chráněná krajinná oblast",
      "type": "protected_area"
    }
  ],
  "verdict": "gray",
  "explanation": "This is a Protected Landscape Area (CHKO). Bivouacking is generally tolerated if you stay one night, arrive late, leave early, and leave no trace. Not officially permitted."
}
```

### Verdicts

| Verdict | Meaning |
|---------|---------|
| `allowed` | Outside protected areas, generally tolerated |
| `gray` | In protected area where bivouacking is tolerated but not officially permitted |
| `forbidden` | Strictly prohibited, may result in fines |

### `GET /map`

Interactive map visualization with click-to-check functionality.

## Frontend

The app includes an interactive web frontend at `/map` built with:

- **Leaflet.js** for map rendering
- **OpenStreetMap** tiles
- Click-to-check functionality that queries the `/check` API
- Visual display of protected areas and military zones
- URL parameter support for sharing locations (`/map?lat=49.68&lng=13.82`)

The frontend displays separate verdicts for:
- **Bivouacking** (sleeping without tent) - more permissive
- **Camping** (with tent) - stricter rules apply

### `GET /up`

Health check endpoint.

## Stack

- **Ruby 3.4** / **Rails 8.1**
- **PostgreSQL 16 + PostGIS 3.4**
- **activerecord-postgis** gem for spatial queries
- Docker Compose for containerization

## Development

```bash
# Start services
docker compose up

# Rails console
docker compose exec api bin/rails console

# Re-import data
docker compose exec api rake import:all

# View logs
docker compose logs -f api
```

## Deployment

Every push to `main` that passes CI publishes `ghcr.io/thykel/camping-guide:latest` (and
`:<commit sha>`). On the server (`/root/camping-guide`, a clone of this repo, with
`COMPOSE_FILE=docker-compose.prod.yml` and the secrets in `.env`), `deploy/update.sh` runs every
minute from `deploy/systemd/camping-update.timer`: when a new image is out, it pulls the repo,
restarts `api` (migrations run on start via `bin/docker-entrypoint`), checks `GET /up` and rolls
back if the new image isn't healthy. Pin a version with `CAMPING_TAG=<commit sha>` in `.env`.

```bash
journalctl -u camping-update -n 20      # what the updater did
```

## Data Sources

Protected area data from OpenStreetMap via Overpass Turbo, stored in `chranene_oblasti.geojson`.

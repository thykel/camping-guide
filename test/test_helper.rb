ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  # Ensure Czechia boundary exists for all tests
  parallelize_setup do |worker|
    ensure_czechia_boundary_exists
  end

  setup do
    ensure_czechia_boundary_exists
  end

  def self.ensure_czechia_boundary_exists
    return if CountryBoundary.exists?(code: "CZ")

    # Simplified Czechia boundary for tests (covers main territory)
    geometry_sql = <<~SQL
      ST_SetSRID(ST_GeomFromText('POLYGON((
        12.09 50.25, 12.55 50.07, 12.95 50.32, 13.18 50.50, 13.85 50.73,
        14.31 51.05, 14.99 51.05, 15.04 50.78, 15.56 50.58, 16.05 50.35,
        16.64 50.21, 17.00 50.00, 17.58 49.63, 18.05 49.44, 18.58 49.12,
        18.87 48.99, 18.04 48.77, 17.37 48.88, 16.95 48.86, 16.43 48.64,
        16.08 48.79, 15.54 48.87, 15.14 48.92, 14.70 48.78, 14.06 48.60,
        13.55 48.78, 13.18 49.02, 12.75 49.12, 12.46 49.44, 12.51 49.95,
        12.09 50.25
      ))'), 4326)::geography
    SQL

    ActiveRecord::Base.connection.execute(<<~SQL)
      INSERT INTO country_boundaries (code, name, geometry, created_at, updated_at)
      VALUES ('CZ', 'Czechia', #{geometry_sql}, NOW(), NOW())
      ON CONFLICT (code) DO NOTHING
    SQL
  end

  def ensure_czechia_boundary_exists
    self.class.ensure_czechia_boundary_exists
  end

  # Helper to create a test polygon geometry
  def create_polygon(coords)
    factory = RGeo::Geographic.spherical_factory(srid: 4326)
    points = coords.map { |lng, lat| factory.point(lng, lat) }
    ring = factory.linear_ring(points)
    polygon = factory.polygon(ring)
    factory.multi_polygon([ polygon ])
  end

  # Sample polygon covering a small area in Czech Republic (around Brdy)
  def brdy_polygon_coords
    [
      [ 13.75, 49.65 ],
      [ 13.90, 49.65 ],
      [ 13.90, 49.75 ],
      [ 13.75, 49.75 ],
      [ 13.75, 49.65 ]
    ]
  end

  # Sample polygon for Šumava NP area
  def sumava_polygon_coords
    [
      [ 13.45, 48.90 ],
      [ 13.60, 48.90 ],
      [ 13.60, 49.05 ],
      [ 13.45, 49.05 ],
      [ 13.45, 48.90 ]
    ]
  end
end

class ActionDispatch::IntegrationTest
  # Helper to parse JSON response
  def json_response
    JSON.parse(response.body)
  end
end

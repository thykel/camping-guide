require "test_helper"

class MapControllerTest < ActionDispatch::IntegrationTest
  setup do
    @area = ProtectedArea.create!(
      name: "Test Area",
      protect_class: "5",
      country: "CZ",
      geometry: create_polygon(brdy_polygon_coords)
    )
  end

  test "index returns HTML with map" do
    get map_url

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_includes response.body, "<!DOCTYPE html>"
    assert_includes response.body, "Can I Sleep There?"
    assert_includes response.body, "leaflet"
  end

  test "index includes map container" do
    get map_url

    assert_response :success
    assert_includes response.body, 'id="map"'
  end

  test "index includes info panel" do
    get map_url

    assert_response :success
    assert_includes response.body, "info-panel"
    assert_includes response.body, "Click anywhere"
  end

  test "areas returns JSON with protected areas" do
    get map_areas_url

    assert_response :success
    assert_equal "application/json", response.media_type

    data = json_response
    assert data.key?("areas")
    assert_kind_of Array, data["areas"]
  end

  test "areas includes area details" do
    get map_areas_url

    assert_response :success

    data = json_response
    area = data["areas"].find { |a| a["name"] == "Test Area" }

    assert_not_nil area
    assert_equal "Test Area", area["name"]
    assert_equal "5", area["protect_class"]
    assert area.key?("coords")
    assert area.key?("id")
  end

  test "areas returns coordinates as array of polygons with lat/lng pairs" do
    get map_areas_url

    assert_response :success

    data = json_response
    area = data["areas"].first
    coords = area["coords"]

    # coords is array of polygons
    assert_kind_of Array, coords
    assert coords.length > 0

    # Each polygon is array of coordinates
    first_polygon = coords.first
    assert_kind_of Array, first_polygon
    assert first_polygon.length > 0

    # Each coordinate should be [lat, lng]
    first_coord = first_polygon.first
    assert_kind_of Array, first_coord
    assert_equal 2, first_coord.length
  end

  test "areas handles empty database" do
    ProtectedArea.destroy_all

    get map_areas_url

    assert_response :success

    data = json_response
    assert_empty data["areas"]
  end

  test "areas handles multiple areas" do
    ProtectedArea.create!(
      name: "Second Area",
      protect_class: "2",
      country: "CZ",
      geometry: create_polygon(sumava_polygon_coords)
    )

    get map_areas_url

    assert_response :success

    data = json_response
    assert_equal 2, data["areas"].length
  end

  private

  def create_polygon(coords)
    factory = RGeo::Geographic.spherical_factory(srid: 4326)
    points = coords.map { |lng, lat| factory.point(lng, lat) }
    ring = factory.linear_ring(points)
    polygon = factory.polygon(ring)
    factory.multi_polygon([ polygon ])
  end

  def brdy_polygon_coords
    [
      [ 13.75, 49.65 ],
      [ 13.90, 49.65 ],
      [ 13.90, 49.75 ],
      [ 13.75, 49.75 ],
      [ 13.75, 49.65 ]
    ]
  end

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

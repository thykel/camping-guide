require "test_helper"

class CheckControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chko = ProtectedArea.create!(
      name: "CHKO Brdy",
      protect_class: "5",
      protection_title: "CHKO",
      country: "CZ",
      geometry: create_polygon(brdy_polygon_coords)
    )
  end

  test "returns camping verdict for valid coordinates" do
    get check_url, params: { lat: 49.70, lng: 13.82 }

    assert_response :success
    assert_equal "application/json", response.media_type

    data = json_response
    assert_equal 49.70, data["lat"]
    assert_equal 13.82, data["lng"]
    assert_equal "allowed", data["verdict"]
    assert_includes data["explanation"], "Protected Landscape"
  end

  test "returns allowed for coordinates outside protected areas" do
    get check_url, params: { lat: 50.08, lng: 14.43 }

    assert_response :success

    data = json_response
    assert_equal "allowed", data["verdict"]
    assert_empty data["areas"]
  end

  test "returns bad request for missing lat" do
    get check_url, params: { lng: 13.82 }

    assert_response :bad_request

    data = json_response
    assert_includes data["error"], "Missing or invalid"
  end

  test "returns bad request for missing lng" do
    get check_url, params: { lat: 49.70 }

    assert_response :bad_request

    data = json_response
    assert_includes data["error"], "Missing or invalid"
  end

  test "returns bad request for missing both coordinates" do
    get check_url

    assert_response :bad_request
  end

  test "returns bad request for lat out of range (too high)" do
    get check_url, params: { lat: 95, lng: 13.82 }

    assert_response :bad_request

    data = json_response
    assert_includes data["error"], "out of range"
  end

  test "returns bad request for lat out of range (too low)" do
    get check_url, params: { lat: -95, lng: 13.82 }

    assert_response :bad_request
  end

  test "returns bad request for lng out of range (too high)" do
    get check_url, params: { lat: 49.70, lng: 185 }

    assert_response :bad_request
  end

  test "returns bad request for lng out of range (too low)" do
    get check_url, params: { lat: 49.70, lng: -185 }

    assert_response :bad_request
  end

  test "handles zero coordinates as invalid" do
    get check_url, params: { lat: 0, lng: 0 }

    assert_response :bad_request
  end

  test "handles string coordinates by converting to float" do
    get check_url, params: { lat: "49.70", lng: "13.82" }

    assert_response :success

    data = json_response
    assert_equal 49.70, data["lat"]
    assert_equal 13.82, data["lng"]
  end

  test "returns areas array with area details" do
    get check_url, params: { lat: 49.70, lng: 13.82 }

    assert_response :success

    data = json_response
    assert_equal 1, data["areas"].length

    area = data["areas"].first
    assert_equal "CHKO Brdy", area["name"]
    assert_equal "5", area["protect_class"]
    assert_equal "protected_area", area["type"]
  end

  test "returns country in response" do
    get check_url, params: { lat: 49.70, lng: 13.82 }

    assert_response :success

    data = json_response
    assert_equal "CZ", data["country"]
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
end

require "test_helper"

class CampingCheckFlowTest < ActionDispatch::IntegrationTest
  setup do
    # Create a realistic set of protected areas
    @chko = ProtectedArea.create!(
      name: "CHKO Brdy",
      protect_class: "5",
      protection_title: "Chráněná krajinná oblast",
      country: "CZ",
      geometry: create_polygon(brdy_polygon_coords)
    )

    @national_park = ProtectedArea.create!(
      name: "Národní park Šumava",
      protect_class: "2",
      protection_title: "národní park",
      country: "CZ",
      geometry: create_polygon(sumava_polygon_coords)
    )

    @strict_reserve = ProtectedArea.create!(
      name: "NPR Boubínský prales",
      protect_class: "1a",
      protection_title: "Národní přírodní rezervace",
      country: "CZ",
      geometry: create_polygon(strict_reserve_coords)
    )
  end

  test "full flow: check CHKO area returns allowed verdict" do
    # User checks a location in CHKO Brdy - bivouacking allowed per 2008 precedent
    get "/check", params: { lat: 49.70, lng: 13.82 }

    assert_response :success

    result = json_response

    # Verify response structure
    assert_equal 49.70, result["lat"]
    assert_equal 13.82, result["lng"]
    assert_equal "CZ", result["country"]
    assert_equal "allowed", result["verdict"]

    # Verify area info
    assert_equal 1, result["areas"].length
    area = result["areas"].first
    assert_equal "CHKO Brdy", area["name"]
    assert_equal "5", area["protect_class"]

    # Verify explanation is helpful
    assert_includes result["explanation"], "tolerated"
    assert_includes result["explanation"], "leave no trace"
  end

  test "full flow: check National Park returns forbidden verdict" do
    # User checks a location in Šumava NP
    get "/check", params: { lat: 48.98, lng: 13.52 }

    assert_response :success

    result = json_response
    assert_equal "forbidden", result["verdict"]
    assert_includes result["explanation"], "designated spots"

    area = result["areas"].first
    assert_equal "Národní park Šumava", area["name"]
    assert_equal "2", area["protect_class"]
  end

  test "full flow: check strict reserve returns forbidden verdict" do
    # User checks a location in strict nature reserve (NPR - Národní přírodní rezervace)
    get "/check", params: { lat: 48.975, lng: 13.825 }

    assert_response :success

    result = json_response
    assert_equal "forbidden", result["verdict"]
    assert_includes result["explanation"], "National Nature Reserve"
    assert_includes result["explanation"], "NPR"
  end

  test "full flow: check area outside protection returns allowed" do
    # User checks a location in Prague (no protection)
    get "/check", params: { lat: 50.08, lng: 14.43 }

    assert_response :success

    result = json_response
    assert_equal "allowed", result["verdict"]
    assert_empty result["areas"]
    assert_includes result["explanation"], "Outside protected areas"
  end

  test "full flow: check map loads and areas endpoint works" do
    # User visits the map
    get "/map"
    assert_response :success
    assert_includes response.body, "Can I Sleep There?"

    # Map fetches areas
    get "/map/areas"
    assert_response :success

    result = json_response
    assert_equal 3, result["areas"].length

    names = result["areas"].map { |a| a["name"] }
    assert_includes names, "CHKO Brdy"
    assert_includes names, "Národní park Šumava"
    assert_includes names, "NPR Boubínský prales"
  end

  test "full flow: health check works" do
    get "/up"
    assert_response :success
  end

  test "protection hierarchy: most restrictive wins" do
    # Create overlapping areas at same location
    overlap_coords = [
      [ 14.40, 50.00 ],
      [ 14.50, 50.00 ],
      [ 14.50, 50.10 ],
      [ 14.40, 50.10 ],
      [ 14.40, 50.00 ]
    ]

    ProtectedArea.create!(
      name: "Outer CHKO",
      protect_class: "5",
      country: "CZ",
      geometry: create_polygon(overlap_coords)
    )

    ProtectedArea.create!(
      name: "Inner National Park",
      protect_class: "2",
      country: "CZ",
      geometry: create_polygon(overlap_coords)
    )

    get "/check", params: { lat: 50.05, lng: 14.45 }

    result = json_response
    assert_equal "forbidden", result["verdict"]
    assert_equal 2, result["areas"].length
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

  def strict_reserve_coords
    [
      [ 13.80, 48.95 ],
      [ 13.85, 48.95 ],
      [ 13.85, 49.00 ],
      [ 13.80, 49.00 ],
      [ 13.80, 48.95 ]
    ]
  end
end

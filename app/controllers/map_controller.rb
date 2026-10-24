class MapController < ActionController::Base
  def index
  end

  def areas
    areas = ProtectedArea.select(:id, :name, :protect_class, :geometry).map do |area|
      {
        id: area.id,
        name: area.name,
        protect_class: area.protect_class,
        coords: extract_coords(area.geometry)
      }
    end

    render json: { areas: areas }
  end

  private

  def extract_coords(geometry)
    return [] unless geometry

    case geometry.geometry_type.to_s
    when "MultiPolygon"
      geometry.map { |polygon| polygon.exterior_ring&.points&.map { |p| [ p.y, p.x ] } || [] }
    when "Polygon"
      [ geometry.exterior_ring&.points&.map { |p| [ p.y, p.x ] } || [] ]
    else
      []
    end
  end
end

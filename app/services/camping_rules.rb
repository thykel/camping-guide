class CampingRules
  VERDICTS = {
    allowed: "allowed",
    forbidden: "forbidden",
    gray: "gray",
    unsupported: "unsupported"
  }.freeze

  # Czech protection categories based on Act 114/1992 Coll.
  # Priority: Use protection_title (Czech category name) over IUCN protect_class
  # Rules based on Czech legal practice and 2008 Hyťha case precedent
  CZECH_CATEGORIES = {
    # Strictest - National Nature Reserves (Národní přírodní rezervace)
    npr: {
      patterns: [ /národní přírodní rezervace/i, /\bNPR\b/ ],
      verdict: VERDICTS[:forbidden]
    },
    # National Natural Monuments (Národní přírodní památka)
    npp: {
      patterns: [ /národní přírodní památka/i, /\bNPP\b/ ],
      verdict: VERDICTS[:forbidden]
    },
    # National Parks (Národní park)
    np: {
      patterns: [ /národní park/i, /\bNP\b/ ],
      verdict: VERDICTS[:forbidden]
    },
    # Nature Reserves (Přírodní rezervace)
    pr: {
      patterns: [ /přírodní rezervace/i, /\bPR\b/ ],
      verdict: VERDICTS[:forbidden]
    },
    # Natural Monuments (Přírodní památka)
    pp: {
      patterns: [ /přírodní památka/i, /\bPP\b/ ],
      verdict: VERDICTS[:forbidden]
    },
    # Regional Landscape Parks (Přírodní park)
    prirodni_park: {
      patterns: [ /přírodní park/i ],
      verdict: VERDICTS[:allowed]
    },
    # Protected Landscape Areas (Chráněná krajinná oblast)
    chko: {
      patterns: [ /chráněná krajinná oblast/i, /\bCHKO\b/ ],
      verdict: VERDICTS[:allowed]
    }
  }.freeze

  # Fallback rules by IUCN protect_class (if protection_title doesn't match)
  RULES_BY_CLASS = {
    "CZ" => {
      "1a" => { verdict: VERDICTS[:forbidden], i18n_key: "camping_rules.iucn.strict_reserve" },
      "1b" => { verdict: VERDICTS[:forbidden], i18n_key: "camping_rules.iucn.wilderness" },
      "2"  => { verdict: VERDICTS[:forbidden], i18n_key: "camping_rules.iucn.national_park" },
      "3"  => { verdict: VERDICTS[:forbidden], i18n_key: "camping_rules.iucn.nature_monument" },
      "4"  => { verdict: VERDICTS[:forbidden], i18n_key: "camping_rules.iucn.nature_reserve" },
      "5"  => { verdict: VERDICTS[:allowed],   i18n_key: "camping_rules.iucn.landscape" }
    }
  }.freeze

  class << self
    def verdict_for_area(area, chko_zone: nil)
      return default_rule unless area

      # First, try to match by Czech protection_title or name prefix
      category = detect_czech_category(area.protection_title, area.name)
      if category
        # For CHKO, refine verdict by zone (I/II = restricted, III/IV = tolerated)
        if category == :chko && chko_zone
          return chko_zone_verdict(chko_zone.zona)
        end

        return {
          verdict: CZECH_CATEGORIES[category][:verdict],
          explanation: I18n.t("camping_rules.categories.#{category}")
        }
      end

      # Fallback to IUCN protect_class
      verdict_by_class(area.country, area.protect_class)
    end

    def verdict_by_class(country, protect_class)
      return default_rule unless country && protect_class

      country_rules = RULES_BY_CLASS[country]
      return default_rule unless country_rules

      rule = country_rules[protect_class]
      return default_rule unless rule

      { verdict: rule[:verdict], explanation: I18n.t(rule[:i18n_key]) }
    end

    def detect_czech_category(protection_title, name = nil)
      # Order matters: check more specific patterns first (NPR before PR, NPP before PP)
      [ :npr, :npp, :np, :pr, :pp, :prirodni_park, :chko ].each do |category|
        patterns = CZECH_CATEGORIES[category][:patterns]
        if protection_title.present? && patterns.any? { |pattern| protection_title.match?(pattern) }
          return category
        end
      end

      # Fallback: check name prefix (e.g., "NPR Xyz", "PP Abc")
      if name.present?
        return :npr if name.match?(/\ANPR\s/i)
        return :npp if name.match?(/\ANPP\s/i)
        return :np if name.match?(/\ANP\s/i)
        return :pr if name.match?(/\APR\s/i)
        return :pp if name.match?(/\APP\s/i)
        return :chko if name.match?(/\ACHKO\s/i)
      end

      nil
    end

    def check_location(lat, lng)
      country = detect_country(lat, lng)

      # Return unsupported for locations outside Czechia
      if country != "CZ"
        outside_czechia_explanation = I18n.t("camping_rules.outside_czechia")
        return {
          lat: lat,
          lng: lng,
          country: country,
          areas: [],
          military_area: nil,
          verdict: VERDICTS[:unsupported],
          explanation: outside_czechia_explanation,
          campfire_verdict: VERDICTS[:unsupported],
          campfire_explanation: outside_czechia_explanation
        }
      end

      # Check military areas first (highest restriction)
      military_area = MilitaryArea.military_area_for_point(lat, lng)
      if military_area
        return {
          lat: lat,
          lng: lng,
          country: country,
          areas: [],
          military_area: {
            name: military_area.name,
            coords: extract_military_coords(military_area.id)
          },
          verdict: VERDICTS[:forbidden],
          explanation: I18n.t("camping_rules.military"),
          campfire_verdict: VERDICTS[:forbidden],
          campfire_explanation: I18n.t("camping_rules.campfire.military"),
          fire_spots: []
        }
      end

      areas = ProtectedArea.containing_point(lat, lng).to_a

      if areas.empty?
        campfire = campfire_rules_for(VERDICTS[:allowed], [], nil)
        return {
          lat: lat,
          lng: lng,
          country: country,
          areas: [],
          military_area: nil,
          verdict: VERDICTS[:allowed],
          explanation: I18n.t("camping_rules.outside_protected"),
          campfire_verdict: campfire[:verdict],
          campfire_explanation: campfire[:explanation],
          fire_spots: []
        }
      end

      chko_zone = ProtectedZone.zone_for_point(lat, lng, kat: "CHKO")
      verdicts = areas.map { |area| verdict_for_area(area, chko_zone: chko_zone) }
      most_restrictive = most_restrictive_verdict(verdicts)
      campfire = campfire_rules_for(most_restrictive[:verdict], areas, nil)
      spots = campfire[:verdict] == VERDICTS[:forbidden] ? nearby_fire_spots(lat, lng) : []

      {
        lat: lat,
        lng: lng,
        country: areas.find { |a| verdict_for_area(a, chko_zone: chko_zone)[:verdict] == most_restrictive[:verdict] }&.country || "CZ",
        areas: areas.map { |a| serialize_area(a, chko_zone: chko_zone) },
        military_area: nil,
        verdict: most_restrictive[:verdict],
        explanation: most_restrictive[:explanation],
        campfire_verdict: campfire[:verdict],
        campfire_explanation: campfire[:explanation],
        fire_spots: spots
      }
    end

    private

    def default_rule
      { verdict: VERDICTS[:gray], explanation: I18n.t("camping_rules.default") }
    end

    def campfire_rules_for(verdict, areas, _military_area)
      categories = areas.map { |a| detect_czech_category(a.protection_title, a.name) }.compact

      # NP: fire only at designated spots
      if categories.include?(:np)
        return { verdict: VERDICTS[:forbidden], explanation: I18n.t("camping_rules.campfire.np") }
      end

      # CHKO: open fire forbidden throughout (§26 Act 114/1992), regardless of zone
      if categories.include?(:chko)
        return { verdict: VERDICTS[:forbidden], explanation: I18n.t("camping_rules.campfire.chko") }
      end

      # Other strictly protected areas (NPR, NPP, PR, PP)
      if verdict == VERDICTS[:forbidden]
        return { verdict: VERDICTS[:forbidden], explanation: I18n.t("camping_rules.campfire.forbidden") }
      end

      # Outside protected areas: forest law applies
      { verdict: VERDICTS[:gray], explanation: I18n.t("camping_rules.campfire.general") }
    end

    def most_restrictive_verdict(verdicts)
      priority = [ VERDICTS[:forbidden], VERDICTS[:gray], VERDICTS[:allowed] ]
      verdicts.min_by { |v| priority.index(v[:verdict]) || 999 }
    end

    def chko_zone_verdict(zona)
      if zona == "I"
        { verdict: VERDICTS[:forbidden], explanation: I18n.t("camping_rules.categories.chko_zone_restricted") }
      else
        { verdict: VERDICTS[:allowed], explanation: I18n.t("camping_rules.categories.chko_zone_tolerated", zona: zona) }
      end
    end

    def serialize_area(area, chko_zone: nil)
      category = detect_czech_category(area.protection_title, area.name)
      result = {
        name: area.name,
        protect_class: area.protect_class,
        protection_title: area.protection_title,
        czech_category: category&.to_s&.upcase,
        type: "protected_area",
        coords: extract_coords(area.geometry)
      }
      if category == :chko && chko_zone
        result[:chko_zone] = chko_zone.zona
        result[:chko_zone_coords] = extract_zone_coords(chko_zone.id)
      end
      result
    end

    def extract_coords(geometry)
      return [] unless geometry

      case geometry.geometry_type.to_s
      when "MultiPolygon"
        geometry.map { |polygon| simplify_coords(polygon_coords(polygon)) }
      when "Polygon"
        [ simplify_coords(polygon_coords(geometry)) ]
      else
        []
      end
    end

    def polygon_coords(polygon)
      polygon.exterior_ring&.points&.map { |p| [ p.y, p.x ] } || []
    end

    def simplify_coords(coords)
      return coords if coords.length <= 200

      step = (coords.length / 100.0).ceil
      coords.each_with_index.select { |_, i| i % step == 0 }.map(&:first)
    end

    def extract_military_coords(military_area_id)
      result = ActiveRecord::Base.connection.exec_query(
        "SELECT ST_AsGeoJSON(geometry::geometry) as geojson FROM military_areas WHERE id = $1",
        "SQL",
        [ military_area_id ]
      )

      return [] if result.empty? || result[0]["geojson"].nil?

      geojson = JSON.parse(result[0]["geojson"])
      coords_data = geojson["coordinates"]

      case geojson["type"]
      when "MultiPolygon"
        coords_data.map { |polygon| simplify_coords(polygon.first.map { |c| [ c[1], c[0] ] }) }
      when "Polygon"
        [ simplify_coords(coords_data.first.map { |c| [ c[1], c[0] ] }) ]
      else
        []
      end
    rescue ActiveRecord::StatementInvalid, JSON::ParserError => e
      Rails.logger.error("Error extracting military coords: #{e.message}")
      []
    end

    def nearby_fire_spots(lat, lng, radius_m: 2000, limit: 5)
      result = ActiveRecord::Base.connection.exec_query(
        <<~SQL,
          SELECT name, lat, lng,
                 ST_Distance(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography)::integer AS distance_m
          FROM fire_spots
          WHERE ST_DWithin(geometry, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $3)
          ORDER BY distance_m
          LIMIT $4
        SQL
        "SQL",
        [ lng, lat, radius_m, limit ]
      )
      result.map { |r| { name: r["name"], lat: r["lat"].to_f, lng: r["lng"].to_f, distance_m: r["distance_m"].to_i } }
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error("Error fetching fire spots: #{e.message}")
      []
    end

    def extract_zone_coords(zone_id)
      result = ActiveRecord::Base.connection.exec_query(
        "SELECT ST_AsGeoJSON(geometry::geometry) as geojson FROM protected_zones WHERE id = $1",
        "SQL",
        [ zone_id ]
      )

      return [] if result.empty? || result[0]["geojson"].nil?

      geojson = JSON.parse(result[0]["geojson"])
      coords_data = geojson["coordinates"]

      case geojson["type"]
      when "MultiPolygon"
        coords_data.map { |polygon| simplify_coords(polygon.first.map { |c| [ c[1], c[0] ] }) }
      when "Polygon"
        [ simplify_coords(coords_data.first.map { |c| [ c[1], c[0] ] }) ]
      else
        []
      end
    rescue ActiveRecord::StatementInvalid, JSON::ParserError => e
      Rails.logger.error("Error extracting zone coords: #{e.message}")
      []
    end

    def detect_country(lat, lng)
      CountryBoundary.country_for_point(lat, lng) || "Unknown"
    end
  end
end

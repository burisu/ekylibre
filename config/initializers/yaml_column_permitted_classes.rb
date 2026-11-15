YAML_COLUMN_PERMITTED_CLASSES =
  [
    ActiveSupport::HashWithIndifferentAccess,
    ActiveSupport::TimeWithZone,
    ActiveSupport::TimeZone,
    ActiveSupport::TimeZone,
    BigDecimal,
    Geo::MultiPolygon,
    Geo::Point,
    Measure,
    Rational,
    RGeo::Geos::CAPIFactory,
    RGeo::Geos::CAPIMultiPolygonImpl,
    RGeo::Geos::CAPIPointImpl,
    RGeo::Geographic::ProjectedMultiPolygonImpl,
    RGeo::Geographic::ProjectedPointImpl,
    RGeo::Geographic::Factory,
    Symbol,
    Time,
    Date,
    Nori::StringWithAttributes
  ]

Rails.application.config.active_record.yaml_column_permitted_classes = YAML_COLUMN_PERMITTED_CLASSES
# Rails >= 7.0 reads it from ActiveRecord itself
ActiveRecord.yaml_column_permitted_classes = YAML_COLUMN_PERMITTED_CLASSES if ActiveRecord.respond_to?(:yaml_column_permitted_classes=)
# ActiveRecord::Base may already be loaded by previous initializers
ActiveSupport.on_load(:active_record) do
  self.yaml_column_permitted_classes = YAML_COLUMN_PERMITTED_CLASSES if respond_to?(:yaml_column_permitted_classes=)
end

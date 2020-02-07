FactoryBot.define do
  factory :product_nature_variant do
    unit_name   { 'Millier de grains' }
    variety     { 'cultivable_zone' }

    association :nature, factory: :product_nature
    association :category, factory: :product_nature_category

    factory :land_parcel_nature_variant do
      association :nature, factory: :land_parcel_nature
      variety { 'land_parcel' }
    end
  end

  factory :worker_variant, parent: :product_nature_variant do
    association :nature, factory: :worker_nature
    variety { 'worker' }
  end

  factory :plant_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Plant variant - TEST#{n.to_s.rjust(8, '0')}" }
    variety         { :triticum }
    unit_name       { :hectare }

    association     :nature, factory: :plants_nature
  end

  factory :corn_plant_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Corn plant variant - TEST#{n.to_s.rjust(8, '0')}" }
    variety         { :zea_mays }
    unit_name       { :hectare }
    association :category, factory: :deliverable_category
    association     :nature, factory: :plants_nature
  end

  factory :deliverable_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Seed #{n}" }
    variety         { 'seed' }
    unit_name       { 'seeds' }

    association :nature, factory: :deliverable_nature
    association :category, factory: :deliverable_category
  end

  factory :service_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Service #{n}" }
    variety         { 'service' }
    unit_name       { 'hour' }

    association :nature, factory: :services_nature
    association :category, factory: :deliverable_category
  end

  factory :equipment_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Equipment variant - TEST#{n.to_s.rjust(8, '0')}" }
    variety         { :tractor }
    unit_name       { :equipment }
    association     :category, factory: :equipment_category
    association :nature, factory: :equipment_nature
  end

  factory :building_division_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Building division variant - #{n}" }
    variety { 'building_division' }
    unit_name { 'Salle' }

    association :nature, factory: :building_division_nature
  end

  factory :fertilizer_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Fertilizer variant - #{n}" }
    variety { :preparation }
    unit_name { :liter }

    association :nature, factory: :fertilizer_nature
  end

  factory :tractor_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Tractor variant - #{n}" }
    variety { :tractor }
    unit_name { 'Tracteur' }

    association :nature, factory: :tractor_nature
  end

  factory :seed_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Seed variant - #{n}" }
    variety { :seed }
    derivative_of { :plant }
    unit_name { 'Millier de grains' }

    association :nature, factory: :seed_nature
  end

  factory :harvest_variant, class: ProductNatureVariant do
    sequence(:name) { |n| "Harvest variant - #{n}" }
    variety { :vegetable }
    derivative_of { :daucus }
    unit_name { 'Kg' }

    association :nature, factory: :harvest_nature
  end
end

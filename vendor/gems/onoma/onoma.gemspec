# -*- encoding: utf-8 -*-
# stub: onoma 0.9.8 ruby lib

Gem::Specification.new do |s|
  s.name = "onoma".freeze
  s.version = "0.9.8".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ekylibre developers".freeze]
  s.date = "2025-05-22"
  s.description = "Actual support Open-Nomenclature data and gem for use".freeze
  s.email = ["dev@ekylibre.com".freeze]
  s.files = ["LICENSE.md".freeze, "bin/console".freeze, "bin/rake".freeze, "bin/setup".freeze, "config/locales/arb.yml".freeze, "config/locales/cmn.yml".freeze, "config/locales/deu.yml".freeze, "config/locales/eng.yml".freeze, "config/locales/fra.yml".freeze, "config/locales/ita.yml".freeze, "config/locales/jpn.yml".freeze, "config/locales/por.yml".freeze, "config/locales/spa.yml".freeze, "db/reference.xml".freeze, "lib/onoma.rb".freeze, "lib/onoma/item.rb".freeze, "lib/onoma/migration/actions/base.rb".freeze, "lib/onoma/migration/actions/item_change.rb".freeze, "lib/onoma/migration/actions/item_creation.rb".freeze, "lib/onoma/migration/actions/item_merging.rb".freeze, "lib/onoma/migration/actions/item_removal.rb".freeze, "lib/onoma/migration/actions/nomenclature_change.rb".freeze, "lib/onoma/migration/actions/nomenclature_creation.rb".freeze, "lib/onoma/migration/actions/nomenclature_removal.rb".freeze, "lib/onoma/migration/actions/property_change.rb".freeze, "lib/onoma/migration/actions/property_creation.rb".freeze, "lib/onoma/migration/base.rb".freeze, "lib/onoma/migrator.rb".freeze, "lib/onoma/migrator/reference.rb".freeze, "lib/onoma/migrator/translation.rb".freeze, "lib/onoma/models/ability.rb".freeze, "lib/onoma/models/account.rb".freeze, "lib/onoma/models/accounting_system.rb".freeze, "lib/onoma/models/activity_family.rb".freeze, "lib/onoma/models/administrative_area.rb".freeze, "lib/onoma/models/administrative_area_nature.rb".freeze, "lib/onoma/models/analysis_nature.rb".freeze, "lib/onoma/models/animal_life_state.rb".freeze, "lib/onoma/models/cation_exchange_capacity_analysis_method.rb".freeze, "lib/onoma/models/chemical_classification.rb".freeze, "lib/onoma/models/chemical_element.rb".freeze, "lib/onoma/models/country.rb".freeze, "lib/onoma/models/crop_set.rb".freeze, "lib/onoma/models/currency.rb".freeze, "lib/onoma/models/delivery_mode.rb".freeze, "lib/onoma/models/dimension.rb".freeze, "lib/onoma/models/document_category.rb".freeze, "lib/onoma/models/document_nature.rb".freeze, "lib/onoma/models/entity_link_nature.rb".freeze, "lib/onoma/models/event_nature.rb".freeze, "lib/onoma/models/fence_perimeter.rb".freeze, "lib/onoma/models/figure.rb".freeze, "lib/onoma/models/fiscal_position.rb".freeze, "lib/onoma/models/guide_nature.rb".freeze, "lib/onoma/models/identifier_nature.rb".freeze, "lib/onoma/models/indicator.rb".freeze, "lib/onoma/models/issue_nature.rb".freeze, "lib/onoma/models/language.rb".freeze, "lib/onoma/models/mammalia_birth_condition.rb".freeze, "lib/onoma/models/mammalia_reproduction_state.rb".freeze, "lib/onoma/models/molecule.rb".freeze, "lib/onoma/models/net_service.rb".freeze, "lib/onoma/models/opportunity_origin.rb".freeze, "lib/onoma/models/phosphorus_analysis_method.rb".freeze, "lib/onoma/models/plant_life_state.rb".freeze, "lib/onoma/models/plant_reproduction_state.rb".freeze, "lib/onoma/models/plants_growth_level.rb".freeze, "lib/onoma/models/procedure_action.rb".freeze, "lib/onoma/models/procedure_category.rb".freeze, "lib/onoma/models/procedure_nature.rb".freeze, "lib/onoma/models/procedure_role.rb".freeze, "lib/onoma/models/product_nature.rb".freeze, "lib/onoma/models/product_nature_category.rb".freeze, "lib/onoma/models/product_nature_variant.rb".freeze, "lib/onoma/models/production_nature.rb".freeze, "lib/onoma/models/production_support_nature.rb".freeze, "lib/onoma/models/production_system.rb".freeze, "lib/onoma/models/production_usage.rb".freeze, "lib/onoma/models/residue_elimination_method.rb".freeze, "lib/onoma/models/role.rb".freeze, "lib/onoma/models/running_cost.rb".freeze, "lib/onoma/models/sex.rb".freeze, "lib/onoma/models/soil_cultural_state.rb".freeze, "lib/onoma/models/soil_nature.rb".freeze, "lib/onoma/models/spatial_reference_system.rb".freeze, "lib/onoma/models/tax.rb".freeze, "lib/onoma/models/tax_nature.rb".freeze, "lib/onoma/models/unit.rb".freeze, "lib/onoma/models/variety.rb".freeze, "lib/onoma/models/working_set.rb".freeze, "lib/onoma/nomenclature.rb".freeze, "lib/onoma/nomenclature_set.rb".freeze, "lib/onoma/property_nature.rb".freeze, "lib/onoma/record/base.rb".freeze, "lib/onoma/reference.rb".freeze, "lib/onoma/reflection.rb".freeze, "lib/onoma/relation.rb".freeze, "lib/onoma/version.rb".freeze, "onoma.gemspec".freeze]
  s.homepage = "https://gitlab.com/ekylibre/onoma".freeze
  s.licenses = ["AGPL-3.0-only".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.4".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Provides open nomenclature data in a gem".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.2".freeze])
  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.10.4".freeze])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.4".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["> 1.15".freeze])
  s.add_development_dependency(%q<i18n-tasks>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["> 12.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 1.3.1".freeze])
end


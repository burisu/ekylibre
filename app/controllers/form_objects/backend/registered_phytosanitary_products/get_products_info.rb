using Ekylibre::Utils::DateSoftParse

module FormObjects
  module Backend
    module RegisteredPhytosanitaryProducts
      class GetProductsInfo < FormObjects::Base
        class << self
          # @return [GetProductsInfo]
          def from_params(params)
            new(params.permit(
                  :intervention_id,
                  :intervention_started_at,
                  :intervention_stopped_at,
                  targets_data: %i[id shape],
                  products_data: %i[product_id usage_id quantity unit_name input_id live_data spray_volume]
                ))
          end
        end

        attr_accessor :targets_data, :products_data, :intervention_started_at, :intervention_stopped_at, :intervention_id

        # @return [DateTime, nil]
        def intervention_started_at
          if @intervention_started_at.nil?
            nil
          else
            DateTime.soft_parse(@intervention_started_at)
          end
        end

        # @return [DateTime, nil]
        def intervention_stopped_at
          if @intervention_stopped_at.nil?
            nil
          else
            DateTime.soft_parse(@intervention_stopped_at)
          end
        end

        def targets_data
          @targets_data&.values || []
        end

        def products_data
          @products_data&.values || {}
        end

        # @return  [Intervention, nil]
        def intervention
          Intervention.find_by_id(@intervention_id)
        end

        def live_data?
          products_data.any? { |pu| pu[:live_data].to_boolean }
        end

        def modified?
          inputs_data = products_data.map { |pu| { input: InterventionInput.find_by_id(pu[:input_id]), product_id: pu[:product_id].to_i, usage_id: pu[:usage_id] } }
          inspector = ::Interventions::Phytosanitary::ParametersInspector.new

          inspector.relevant_parameters_modified?(live_data: live_data?, intervention: intervention, targets_ids: targets_ids, inputs_data: inputs_data)
        end

        def targets_zone
          @targets_zone ||= ::Interventions::Phytosanitary::Models::TargetZone.from_targets_data(targets_data)
        end

        def targets_ids
          @targets_ids ||= targets_data.map { |data| data[:id].to_i }
        end

        def products_and_usages_ids
          @products_and_usages_ids || []
        end

        # @return [Array<Plant, LandParcel>]
        def targets
          targets_zone.map(&:target)
        end

        def products_and_usages
          modified = modified?

          @products_and_usages ||= products_data.map do |pu|
            product = Product.find_by(id: pu[:product_id])
            input = InterventionInput.find_by(id: pu[:input_id])
            phyto = fetch_phyto(modified, input, product)
            usage = fetch_usage(modified, input, pu[:usage_id])
            measure = Measure.new(pu[:quantity].to_f, pu[:unit_name])
            spray_volume = nil # pu[:spray_volume].blank? ? nil : pu[:spray_volume].to_d

            ::Interventions::Phytosanitary::Models::ProductWithUsage.new(product, phyto, usage, measure, spray_volume)
          end.reject { |pu| pu.product.nil? }
        end

        private

          def fetch_usage(modified, input, usage_id)
            if !modified && input.reference_data['usage'].present?
              InterventionParameter::LoggedPhytosanitaryUsage.new(input.reference_data['usage'])
            else
              RegisteredPhytosanitaryUsage.find_by_id(usage_id)
            end
          end

          def fetch_phyto(modified, input, product)
            if !modified && input.reference_data['product'].present?
              InterventionParameter::LoggedPhytosanitaryProduct.new(input.reference_data['product'])
            else
              product.phytosanitary_product
            end
          end
      end
    end
  end
end

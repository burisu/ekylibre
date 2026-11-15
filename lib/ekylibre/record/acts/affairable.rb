module Ekylibre
  module Record
    module Acts #:nodoc:
      # Links a model (sale, payment...) to an affair which groups the deals of
      # a third. Configuration is stored in +affairable_options+ and read by
      # plain instance methods (no generated code).
      module Affairable #:nodoc:
        def self.included(base)
          base.extend(ClassMethods)
        end

        AFFAIR_DELEGATED_DEFAULTS = {
          credit: 0,
          debit: 0,
          closed: false,
          balance: 0,
          status: 'stop'
        }.freeze

        module ClassMethods
          def acts_as_affairable(*args)
            options = args.extract_options!
            options[:dealt_at] ||= :created_at
            options[:amount] ||= :amount
            options[:debit] = true unless options.key?(:debit)
            unless [true, false].include?(options[:debit]) || options[:debit].is_a?(Symbol)
              raise ArgumentError.new('Option :debit must be boolean or Symbol')
            end

            options[:third] ||= args.shift || :third
            options[:role] ||= options[:third].to_s
            options[:good] ||= :debit
            options[:class_name] ||= name + 'Affair'
            options[:currency] ||= :currency

            reflection_name = options[:reflection] || :affair
            foreign_key = options[:foreign_key] || :affair_id
            if (reflection = reflect_on_association(reflection_name))
              reflection_name = reflection.name
              foreign_key = reflection.foreign_key
            else
              unless columns_definition[foreign_key]
                Rails.logger.fatal 'Unable to acts as affairable without affair column'
              end
              belongs_to reflection_name, inverse_of: name.underscore.pluralize.to_sym, foreign_key: foreign_key
            end
            options[:reflection] = reflection_name.to_sym
            options[:foreign_key] = foreign_key.to_sym

            class_attribute :affairable_options, instance_writer: false
            self.affairable_options = options.freeze

            include InstanceMethods
            extend AffairableClassMethods

            scope :affairable, -> { where(reflection_name => Affair.opened) }

            # Need to log strange things on delegate
            AFFAIR_DELEGATED_DEFAULTS.each do |meth, default_value|
              define_method("#{reflection_name}_#{meth}") do
                affair = send(reflection_name)
                unless affair
                  Rails.logger.warn "No affair on #{self.class.name} ID=#{id}"
                  return default_value
                end
                affair.send(meth)
              end
            end
            alias_method :"#{reflection_name}_closed?", :"#{reflection_name}_closed"

            validate :check_affair_currency
            after_save :refresh_affair_after_save
            after_destroy :refresh_affair_after_destroy

            # Computes taxes based on opposite operation unless given
            if options[:taxes].is_a?(Symbol)
              define_method(:deal_taxes) { |*args| send(affairable_options[:taxes], *args) }
            elsif options[:taxes] != true
              define_method(:deal_taxes) do |mode = :debit|
                amount = deal_mode_amount(mode)
                amount.zero? ? [] : [{ amount: amount }]
              end
            end
          end
        end

        module AffairableClassMethods
          # Reflection of the third of the deal
          def deal_third
            reflect_on_association(affairable_options[:third])
          end

          def affairable?
            true
          end
        end

        module InstanceMethods
          def deal_amount
            send(affairable_options[:amount])
          end

          def dealt_at
            send(affairable_options[:dealt_at])
          end

          def deal_third
            send(affairable_options[:third])
          end

          def can_be_dealt_with?(affair)
            valid_affair_class?(affair) && !invalid_currency?(affair)
          end

          def deal_with!(affair, dones = [])
            unless valid_affair_class?(affair)
              raise "#{affair.class.name} (ID=#{affair.id}) cannot be merged in #{affairable_options[:class_name]}"
            end
            return self if send(affairable_options[:foreign_key]) == affair.id

            dones << self
            if invalid_currency?(affair)
              raise ArgumentError, "The currency (#{currency}) is different of the affair currency(#{affair.currency})"
            end

            ApplicationRecord.transaction do
              if (old_affair = current_affair)
                other_deals.each do |deal|
                  deal.deal_with!(affair, dones) unless dones.include?(deal)
                end
                affair_class.destroy(old_affair.id) if affair_class.find_by(id: old_affair.id)
              end
              update_column(affairable_options[:foreign_key], affair.id)
              affair.refresh!
            end
            reload
          end

          def undeal!(from_affair = nil)
            if from_affair && from_affair.id != send(affairable_options[:foreign_key])
              raise ArgumentError, "Cannot undeal from this unknown affair ##{from_affair.id}"
            end

            ApplicationRecord.transaction do
              old_affair = current_affair
              affair = affair_class.create!(currency: currency, third: deal_third)
              update_column(affairable_options[:foreign_key], affair.id)
              affair.refresh!
              old_affair.refresh!
              old_affair.destroy! if old_affair.deals_count.zero?
            end
          end

          def detachable?
            other_deals.any?
          end

          # Returns if deal is a debit for us
          def good_deal?
            case affairable_options[:good]
            when :debit then deal_debit?
            when :credit then deal_credit?
            else send(affairable_options[:good])
            end
          end

          # Returns if deal is a debit for us
          def deal_debit?
            debit = affairable_options[:debit]
            debit.is_a?(Symbol) ? send(debit) : debit
          end

          # Returns if deal is a credit for us
          def deal_credit?
            !deal_debit?
          end

          def our_deal_balance
            deal_mode_amount('real_credit - real_debit')
          end

          def third_deal_balance
            deal_mode_amount('real_debit - real_credit')
          end

          def deal_debit_amount
            deal_mode_amount(:debit)
          end

          def deal_credit_amount
            deal_mode_amount(:credit)
          end

          def deal_mode_amount(mode)
            return 0 unless journal_entry && affair

            journal_entry.items.where(account: affair.third_account).sum(mode.is_a?(Symbol) ? "real_#{mode}" : Arel.sql(mode))
          end

          # Returns other deals
          def other_deals
            fetch_affair!.deals.delete_if { |x| x == self }
          end

          # Initialize linked affair
          def fetch_affair!
            return current_affair if current_affair

            new_affair = affair_class.create!(currency: send(affairable_options[:currency]), third: deal_third)
            deal_with!(new_affair)
            new_affair
          end

          def other_deals_of_same_type
            fetch_affair!.deals.delete_if { |x| x == self || !x.is_a?(self.class) }
          end

          private

            def current_affair
              send(affairable_options[:reflection])
            end

            def affair_class
              affairable_options[:class_name].constantize
            end

            def valid_affair_class?(affair)
              affair.is_a?(affair_class)
            end

            def invalid_currency?(affair)
              currency != affair.currency
            end

            def check_affair_currency
              affair = current_affair
              return unless affair

              currency_name = affairable_options[:currency]
              if affair.currency? && send("#{currency_name}?") && affair.currency != send(currency_name)
                raise "Invalid currency in affair. Expecting: #{currency}. Got: #{affair.currency}"
              end
            end

            def refresh_affair_after_save
              if current_affair
                current_affair.refresh!
              else
                fetch_affair!
              end
            end

            def refresh_affair_after_destroy
              current_affair&.refresh!
            end
        end
      end
    end
  end
end

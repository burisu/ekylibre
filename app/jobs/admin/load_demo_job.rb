module Admin
  # Holds status key constants and status accessors used by both
  # the controller (status polling) and the rake task (admin:demo:load).
  class LoadDemoJob < ApplicationJob
    STATUS_KEY   = 'ekylibre:admin:demo'.freeze
    DEMO_FOLDER = 'demo'.freeze
    TENANT_NAME = 'demo'.freeze

    LOADER_LABELS = {
      'base'            => 'Paramètres de base',
      'entities'        => 'Entités / Contacts',
      'land_parcels'    => 'Parcelles',
      'buildings'       => 'Bâtiments',
      'equipments'      => 'Équipements',
      'workers'         => 'Employés',
      'products'        => 'Produits',
      'animals'         => 'Animaux',
      'productions'     => 'Productions',
      'analyses'        => 'Analyses',
      'sales'           => 'Ventes',
      'deliveries'      => 'Livraisons',
      'purchases'       => 'Achats',
      'bank_statements' => 'Relevés bancaires',
      'cash_transfers'  => 'Virements',
      'interventions'   => 'Interventions',
      'accountancy'     => 'Comptabilité'
    }.freeze

    def self.current_status
      result = Ekylibre::TaskStatus.read(STATUS_KEY)
      {
        status:      result['status']      || 'idle',
        message:     result['message']     || '',
        step:        result['step']&.to_i,
        total_steps: result['total_steps']&.to_i
      }
    end

    def self.reset!
      Ekylibre::TaskStatus.delete(STATUS_KEY)
    end
  end
end

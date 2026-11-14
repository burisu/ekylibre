module Clients
  module Gouv
    class AddressClient
      BASE_URL = 'https://api-adresse.data.gouv.fr/search/'.freeze

      def get_address(address)
        call = Clients::Http.get(BASE_URL, params: { q: address, type: 'housenumber', autocomplete: 0 })
        JSON.parse(call.body).deep_symbolize_keys
      end
    end
  end
end

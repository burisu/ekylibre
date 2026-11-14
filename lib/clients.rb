# Gathers all specific calculations
module Clients
  autoload :Http,    'clients/http'
  autoload :Gouv,    'clients/gouv'
  autoload :Insee,   'clients/insee'
  autoload :Mistral, 'clients/mistral'
end

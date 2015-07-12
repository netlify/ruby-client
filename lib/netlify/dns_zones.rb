require "netlify/dns_zone"

module Netlify
  class DnsZones < CollectionProxy
    path "/dns_zones"

    def dns_records
      DnsRecords.new(client, path)
    end
  end
end

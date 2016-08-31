module Netlify
  class DnsRecord < Model
    fields :id, :hostname, :type, :value, :ttl, :domain_id, :managed
  end
end

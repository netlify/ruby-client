require "netlify/dns_record"

module Netlify
  class DnsRecords < CollectionProxy
    path "/dns_records"
  end
end

require "netlify/dns_records"

module Netlify
  class DeployKey < Model
    fields :id, :public_key, :created_at
  end
end

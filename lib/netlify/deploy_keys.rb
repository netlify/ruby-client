require "netlify/deploy_key"

module Netlify
  class DeployKeys < CollectionProxy
    path "/deploy_keys"
  end
end

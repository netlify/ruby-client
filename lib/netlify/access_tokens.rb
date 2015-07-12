require "netlify/access_token"

module Netlify
  class AccessTokens < CollectionProxy
    path "/access_tokens"
  end
end

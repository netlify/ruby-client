require "netlify/user"

module Netlify
  class Users < CollectionProxy
    path "/users"
  end
end

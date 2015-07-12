require "netlify/snippet"

module Netlify
  class Snippets < CollectionProxy
    path "/snippets"
  end
end

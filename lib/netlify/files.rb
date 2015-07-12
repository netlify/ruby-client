require "netlify/file"

module Netlify
  class Files < CollectionProxy
    path "/files"
  end
end

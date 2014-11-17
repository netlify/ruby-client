require "Netlify/submission"

module Netlify
  class Submissions < CollectionProxy
    path "/submissions"
  end
end
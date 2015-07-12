require "netlify/submission"

module Netlify
  class Submissions < CollectionProxy
    path "/submissions"
  end
end

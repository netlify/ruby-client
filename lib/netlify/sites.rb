require "netlify/site"
require "digest/sha1"

module Netlify
  class Sites < CollectionProxy
    path "/sites"

    def create(attributes = {})
      response = client.request(:post, path, :body => Site.new(client, {}).send(:mutable_attributes, attributes))
      Site.new(client, response.parsed).tap do |site|
        if attributes[:zip] || attributes[:tar] || attributes[:dir]
          deploy = site.deploys.create(attributes)
          site.deploy_id = deploy.id
        elsif attributes[:github]
          site.configure_github!(attributes[:github])
        end
      end
    end
  end
end

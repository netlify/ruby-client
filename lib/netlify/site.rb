require 'digest/sha1'
require 'uri'

module Netlify
  class Site < Model
    fields :id, :state, :premium, :claimed, :name, :custom_domain, :url,
           :admin_url, :deploy_id, :build_id, :deploy_url, :screenshot_url, :created_at, :updated_at,
           :password, :notification_email, :user_id, :error_message, :required, :deploy_hook

    def ready?
      state == "current"
    end

    def error?
      state == "error"
    end

    def wait_for_ready(timeout = 900, &block)
      deploy = deploys.get(deploy_id)
      raise "Error fetching deploy #{deploy_id}" unless deploy
      deploy.wait_for_ready(timeout, &block)
      self
    end

    def update(attributes)
      response = client.request(:put, path, :body => mutable_attributes(attributes))
      process(response.parsed)
      if attributes[:zip] || attributes[:tar] || attributes[:dir]
        deploy = deploys.create(attributes)
        self.deploy_id = deploy.id
      end
      self
    end

    def configure_github!(options)
      raise Client::NetlifyError, "You must specify a Github access_token" unless options[:access_token]
      raise Client::NetlifyError, "You must specify a Github repo" unless options[:repo]
      require "github_api"

      _, user, repo = *options[:repo].match(/^([^\/]+)\/([^\/]+)$/)
      unless user && repo
        raise Client::NetlifyError, "Invalid github repo #{options[:repo]}"
      end

      github = Github.new(:oauth_token => options[:access_token])
      deploy_key = client.deploy_keys.create({})
      github.repos.keys.create(user, repo, title: "Netlify", key: deploy_key.public_key)
      response = client.request(:put, path, :body => {
        :github => {
          :repo => options[:repo],
          :deploy_key_id => deploy_key.id,
          :dir => options[:dir],
          :cmd => options[:cmd],
          :branch => options[:branch],
          :env => options[:env]
        }
      })
      process(response.parsed)
      github.repos.hooks.create(user, repo, name: "web", active: true, events: ["push"], config: {
        url: deploy_hook,
        content_type: 'json'
      })
      self
    end

    def destroy!
      client.request(:delete, path)
      true
    end

    def forms
      Forms.new(client, path)
    end

    def submissions
      Submissions.new(client, path)
    end

    def files
      Files.new(client, path)
    end

    def snippets
      Snippets.new(client, path)
    end

    def deploys
      Deploys.new(client, path)
    end

    private
    def mutable_attributes(attributes)
      Hash[*[:name, :custom_domain, :password, :notification_email].map {|key|
        if attributes.has_key?(key) || attributes.has_key?(key.to_s)
          [key, attributes[key] || attributes[key.to_s]]
        end
      }.compact.flatten]
    end
  end
end

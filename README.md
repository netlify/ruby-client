# This code is deprecated.  Our current API interface can be found here:  https://github.com/netlify/open-api/

## Netlify Ruby Client
======================

Netlify is a hosting service for the programmable web. It understands your documents, processes forms and lets you do deploys, manage forms submissions, inject javascript snippets into sites and do intelligent updates of HTML documents through it's API.

The basic flow to using the ruby client is:

1. Authenticate (via credentials or a previously aquired access token)
2. Get site (via id)
3. Deploy
  * If site has not been deployed to yet, then the above step will throw a `not found` exception, and you'll need to use `Netlify.sites.create` to create the site and do the initial deploy.
  * If the site has already been deployed and the above step was successful, you can simply use `site.update` to re-deploy.

If you'd rather, there's also a command line utility to handle most of these steps: `Netlify deploy`.

## Installation
============

Install the gem by running

    gem install netlify

or put it in a Gemfile and run `bundle install`

    gem netlify


## Authenticating
==============

Register a new application at https://app.netlify.com/applications to get your Oauth2 secret and key.

Once you have your credentials you can instantiate a Netlify client.

```ruby
Netlify = Netlify::Client.new(:client_id => "YOUR_API_KEY", :client_secret => "YOUR_API_SECRET")
```

Before you can make any requests to the API, you'll need to authenticate with OAuth2. The Netlify client supports two OAuth2 flows.

If you're authenticating on behalf of a user, you'll need to get a valid access token for that user. Use the Netlify client to request an authentication URL:

```ruby
url = Netlify.authorize_url(:redirect_uri => "http://www.example.com/callback")
```

The user then visits that URL and will be prompted to authorize your application to access his Netlify sites. If she grants permission, she'll be redirected back to the `redirect_uri` provided in the `authorize_url` call. This URL must match the redirect url configured for your Netlify application. Once the user comes back to your app, you'll be able to access a `code` query parameter that gives you an authorization code. Use this to finish the OAuth2 flow:

```ruby
Netlify.authorize!(token, :redirect_uri => "http://www.example.com/callback")
```

If you're not authenticating on behalf of a user you can authorize directly with the API credentials. Just call:

```ruby
Netlify.authorize_from_credentials!
```

If you already have an OAuth2 `access_token` you can instantiate the client like this:

```ruby
Netlify = Netlify::Client.new(:access_token => access_token)
```

And the client will be ready to do requests without having to use `authorize_from_credentials`. This means that once you've gotten a token via `authorize_from_credentials!` you can store it and reuse it for later sessions.

If you're authenticating via the `access_token` and you'd like to test if you have a valid `access_token`, you can attempt to make a request with the Netlify client and if the token is invalid, a `Netlify::Client::AuthenticationError` will be raised. See Miles Matthias' [Netlify Rakefile](https://github.com/milesmatthias/Netlify-rakefile) for an example.


## Sites
=====

Getting a list of all sites you have access to:

```ruby
Netlify.sites.each do |site|
  puts site.id
  puts site.url
end
```

Each site has a unique, system generated id. Getting a specific site by id:

```ruby
site = Netlify.sites.get(id)
```

Creating a site from a directory: _(note the path given is a system path)_

```ruby
site = Netlify.sites.create(:dir => "my-site")
puts site.id
```

You'll want to then save that site id for future reference. Note that a site can also be looked up by its `url`.

Creating a site from a zip file:

```ruby
site = Netlify.sites.create(:zip => "/tmp/my-site.zip")
```

Both methods will create the site and upload the files to a new deploy.

Creating a site with a dir or a zip is actually a shortcut for this:

```ruby
site = Netlify.sites.create(:name => "unique-site-subdomain", :custom_domain => "www.example.com")
deploy = site.deploys.create(:dir => "path/to/my-site")
```

Use `wait_for_ready` to wait until a site has finished processing.

```ruby
site = Netlify.sites.create(:dir => "/tmp/my-site")
site.wait_for_ready
site.state == "ready"
```

This also works on a specific deploy, and you can pass in a block to execute after each polling action:

```ruby
deploy = site.deploys.create(:dir => "/tmp/my-site")
deploy.wait_for_ready do |deploy|
  puts "Current state: #{deploy.state}"
end
```

Redeploy a site from a dir:

```ruby
site = Netlify.sites.get(site_id)
deploy = site.deploys.create(:dir => "/tmp/my-site")
deploy.wait_for_ready
```

Redeploy a site from a zip file:

```ruby
site = Netlify.sites.get(site_id)
deploy = site.deploys.create(:zip => "/tmp/my-site.zip")
deploy.wait_for_ready
```

Update the name of the site (its subdomain), the custom domain and the notification email for form submissions:

```ruby
    site.update(:name => "my-site", :custom_domain => "www.example.com", :notification_email => "me@example.com", :password => "secret-password")
```

Deleting a site:

```ruby
    site.destroy!
```

## Deploys
=======

Access all deploys for a site

```ruby
site = Netlify.sites.get(site_id)
site.deploys.all
```

Access a specific deploy

```ruby
site = Netlify.sites.get(site_id)
deploy = site.deploys.get(id)
```

Publish a deploy (makes it the current live version of the site)

```ruby
site.deploys.get(id).publish
```

Create a new deploy

```ruby
deploy = site.deploys.create(:dir => "/tmp/my-site")
```

Create a draft deploy

```ruby
deploy = site.deploys.draft(:dir => "/tmp/my-site")
```

Or

```ruby
deploy = site.deploys.create(:dir => "/tmp/my-site", :draft => true)
```

This will upload and process a deploy. You can view the deploy at `deploy.deploy_url` and make it the live version of the site with `deploy.publish`.

## Continuous Deployment
=====================

You can also configure continuous deployment for a new or existing site from the Ruby client.

You'll need a Github access token (this will never get sent to Netlify) in addition to your Netlify token. Make sure this access token have the permission to add a deploy key and a web hook to your repository.

Create a new site with continuous deployment:

```ruby
client.sites.create(:github => {
    :repo => "netlify/example",
    :dir => "build",
    :cmd => "middleman build",
    :access_token => GITHUB_ACCESS_TOKEN
})
```

Configure continuous deployment for an existing site:

```ruby
site.configure_github!(
  :repo => "netlify/example",
  :dir => "build",
  :cmd => "middleman build",
  :access_token => GITHUB_ACCESS_TOKEN
)
```

Forms
=====

Access all forms you have access to:

```ruby
    Netlify.forms.all
```

Access forms for a specific site:

```ruby
    site = Netlify.sites.get(id)
    site.forms.all
```

Access a specific form:

```ruby
    form = Netlify.forms.get(id)
```

Access a list of all form submissions you have access to:

```ruby
    Netlify.submissions.all
```

Access submissions from a specific site

```ruby
    site = Netlify.sites.get(id)
    site.submissions.all
```

Access submissions from a specific form

```ruby
    form = Netlify.forms.get(id)
    form.submissions.all
```

Get a specific submission

```ruby
    Netlify.submissions.get(id)
```

Files
=====

Access all files in a site:

```ruby
    site = Netlify.sites.get(id)
    site.files.all
```

Get a specific file:

```ruby
    file = site.files.get(path) # Example paths: "/css/main.css", "/index.html"
```

Reading a file:

```ruby
    file.read
```

## Snippets
========

Snippets are small code snippets injected into all HTML pages of a site right before the closing head or body tag. To get all snippets for a site:

```ruby
site = Netlify.sites.get(id)
site.snippets.all
```

Get a specific snippet

```ruby
site.snippets.get(0)
```

Add a snippet to a site.

You can specify a `general` snippet that will be inserted into all pages, and a `goal` snippet that will be injected into a page following a successful form submission. Each snippet must have a title. You can optionally set the position of both the general and the goal snippet to `head` or `footer` to determine if it gets injected into the head tag or at the end of the page.

```ruby
site.snippets.create(
  :general => general_snippet,
  :general_position => "footer",
  :goal => goal_snippet,
  :goal_position => "head",
  :title => "My Snippet"
)
```

Update a snippet

```ruby
site.snippets.get(id).update(
  :general => general_snippet,
  :general_position => "footer",
  :goal => goal_snippet,
  :goal_position => "head",
  :title => "My Snippet"
)
```

Remove a snippet

```ruby
site.snippet.get(id).destroy
end
```

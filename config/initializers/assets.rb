# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

Rails.application.config.assets.precompile += %w( site_images/collection-icon.svg )
Rails.application.config.assets.precompile += %w( default.png )
Rails.application.config.assets.precompile += %w( missing_thumb.png )
Rails.application.config.assets.precompile += %w( orcid.png )

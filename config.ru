require 'bundler'
Bundler.require

require 'sass/plugin/rack'
require 'compass'
require 'rack/sass_compiler'
require 'rack/coffee_compiler'
require File.join(File.dirname(__FILE__), 'app.rb')

# Use scss for stylesheets
Sass::Plugin.options[:style] = :compressed

use Rack::Cache

use Rack::SassCompiler,
  :source_dir => 'public/stylesheets/sass',
  :url => '/stylesheets'

use Rack::CoffeeCompiler,
  :source_dir => 'public/javascripts',
  :url => '/javascripts'

run App

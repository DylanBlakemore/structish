require 'bundler/setup'
require 'pry'
require 'simplecov'

SimpleCov.start do
  add_filter "/spec/"
  minimum_coverage 99.5
  maximum_coverage_drop 0.5
end

require 'structish'

Bundler.setup

require 'bundler/setup'
require 'pry'
require 'simplecov'

SimpleCov.start do
  add_filter "/spec/"
  minimum_coverage 100
  maximum_coverage_drop 0
end

require 'structish'

Bundler.setup

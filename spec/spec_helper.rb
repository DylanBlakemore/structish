require 'bundler/setup'
require 'pry'
require 'simple_cov'
require 'codecov'
require 'structish'

Bundler.setup


SimpleCov.start
SimpleCov.formatter = SimpleCov::Formatter::Codecov

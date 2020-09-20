source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gemspec

gem "activesupport", "~> 4.0"

group :test do
  gem "rspec"
  gem "factory_bot"
end

group :test, :development do
  gem "pry"
  gem "pry-byebug"
end

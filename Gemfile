source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gemspec

group :test do
  gem "rspec"
  gem "simplecov", :require => false
end

group :test, :development do
  gem "pry"
  gem "pry-byebug"
end

$:.push File.expand_path("lib", __dir__)

# Maintain gem's version:
require "associate_jsonb/version"

Gem::Specification.new do |s|
  s.name        = "associate_jsonb"
  s.version     = AssociateJsonb::VERSION
  s.authors     = ["Sampson Crowley", "Yury Lebedev"]
  s.email       = ["sampsonsprojects@gmail.com"]
  s.homepage    = "https://github.com/SampsonCrowley/associate_jsonb"
  s.license     = "MIT"
  s.summary     = "Store database references in PostgreSQL Jsonb columns"
  s.description = <<-BODY
    This gem extends ActiveRecord to let you use json data for associations
    Inspired by activerecord-jsonb-associations, but for use in Rails 6+ and
    ruby 2.7+
  BODY

  s.files = Dir[
    "{app,config,db,lib}/**/*",
    "MIT-LICENSE",
    "Rakefile",
    "README.md"
  ]

  s.required_ruby_version = ">= 2.7"

  s.add_dependency "rails",    "~> 6",   ">= 6.0.3.1"
  s.add_dependency "pg",       "~> 1.1", ">= 1.1.2"
  s.add_dependency "zeitwerk", "~> 2",   ">= 2.2.2"
  s.add_dependency "mutex_m",  "~> 0.1", ">= 0.1.0"

  s.add_development_dependency "rspec", "~> 3.7.0"
end

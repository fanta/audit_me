# -*- encoding: utf-8 -*-
require File.expand_path('../lib/audit_me/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Sergio Figueroa', 'Ignacio Galindo']
  gem.email         = ['sergio.figuero@crowdint.com', 'ignacio.galindo@crowdint.com']
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = 'http://github.com/crowdint/audit_me'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "audit_me"
  gem.require_paths = ["lib"]
  gem.version       = AuditMe::VERSION

  gem.add_dependency 'railties', '3.0'
  gem.add_dependency 'activerecord', '3.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'shoulda', '2.10.3'
  gem.add_development_dependency 'sqlite3', '~> 1.2'
  gem.add_development_dependency 'capybara', '~> 1.0.0'
end

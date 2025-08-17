# -*- encoding: utf-8 -*-
# stub: tosspayments-rails 0.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "tosspayments-rails".freeze
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/luciuschoi/tosspayments-rails/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/luciuschoi/tosspayments-rails", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/luciuschoi/tosspayments-rails" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lucius Choi".freeze]
  s.bindir = "exe".freeze
  s.date = "2025-08-17"
  s.description = "\uD1A0\uC2A4\uD398\uC774\uBA3C\uCE20 API\uB97C \uC0AC\uC6A9\uD558\uC5EC Rails \uC560\uD50C\uB9AC\uCF00\uC774\uC158\uC5D0\uC11C \uC628\uB77C\uC778 \uACB0\uC81C \uAE30\uB2A5\uC744 \uC27D\uAC8C \uAD6C\uD604\uD560 \uC218 \uC788\uB294 gem\uC785\uB2C8\uB2E4. Rails 7+ (\uBC0F Rails 8) \uBC84\uC804\uC744 \uC9C0\uC6D0\uD558\uBA70 Rails credentials\uB97C \uD1B5\uD55C \uC548\uC804\uD55C \uC124\uC815 \uAD00\uB9AC\uB97C \uC81C\uACF5\uD569\uB2C8\uB2E4.".freeze
  s.email = ["lucius.choi@gmail.com".freeze]
  s.homepage = "https://github.com/luciuschoi/tosspayments-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.2".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "\uD1A0\uC2A4\uD398\uC774\uBA3C\uCE20 \uC628\uB77C\uC778 \uACB0\uC81C \uC11C\uBE44\uC2A4\uB97C \uC704\uD55C Rails gem".freeze

  s.installed_by_version = "3.3.7" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<faraday>.freeze, ["~> 2.0"])
    s.add_runtime_dependency(%q<faraday-net_http>.freeze, ["~> 3.0"])
    s.add_runtime_dependency(%q<rails>.freeze, [">= 7.0", "< 9.0"])
  else
    s.add_dependency(%q<faraday>.freeze, ["~> 2.0"])
    s.add_dependency(%q<faraday-net_http>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rails>.freeze, [">= 7.0", "< 9.0"])
  end
end

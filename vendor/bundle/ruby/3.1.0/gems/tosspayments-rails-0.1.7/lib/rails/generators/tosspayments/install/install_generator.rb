# frozen_string_literal: true

# Conventional Rails generator lookup path alias.
# Some Rails versions and tools search under lib/rails/generators/<namespace>/<name>/<name>_generator.rb
# Primary implementation lives at: lib/generators/tosspayments/install_generator.rb
# We expose a subclass here so either lookup strategy resolves.

require_relative '../../../../generators/tosspayments/install_generator'

module Tosspayments
  module Generators
    class InstallGenerator < ::Tosspayments::InstallGenerator
      # 별칭 제너레이터에서도 템플릿 경로를 확실히 인지시키기 위해 명시 지정
      source_root File.expand_path('../../../../generators/tosspayments/templates', __dir__)
    end
  end
end

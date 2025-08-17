# frozen_string_literal: true

# Conventional Rails generator lookup path alias.
# Some Rails versions and tools search under lib/rails/generators/<namespace>/<name>/<name>_generator.rb
# Primary implementation lives at: lib/generators/tosspayments/install_generator.rb
# We expose a subclass here so either lookup strategy resolves.

require_relative '../../../../generators/tosspayments/install_generator'

module Tosspayments
  module Generators
    class InstallGenerator < ::Tosspayments::InstallGenerator
    end
  end
end

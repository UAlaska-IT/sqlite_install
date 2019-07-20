# frozen_string_literal: true

if defined?(ChefSpec)
  ChefSpec.define_matcher(:sqlite_installation)

  def create_sqlite_installation(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:sqlite_installation, :create, resource)
  end
end

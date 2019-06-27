# frozen_string_literal: true

resource_name :sqlite_installation
provides :sqlite_installation

default_action :create

property :version, String, required: true
property :install_directory, String, name_property: true
property :owner, String, default: 'root'
property :group, String, default: 'root'

action :create do
  create_sqlite_install(@new_resource)
end

action_class do
  include SqliteInstall::Helper
end

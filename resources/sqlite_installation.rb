# frozen_string_literal: true

resource_name :sqlite_installation
provides :sqlite_installation

default_action :create

property :year, String, default: '2019'
property :version, String, default: '3280000'
property :download_directory, [String, nil], default: nil
property :build_directory, [String, nil], default: nil
property :install_directory, [String, nil], default: nil
property :owner, String, default: 'root'
property :group, String, default: 'root'

action :create do
  create_install(@new_resource)
end

action_class do
  include SqliteInstall::Install
end

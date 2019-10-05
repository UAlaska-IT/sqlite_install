# frozen_string_literal: true

require 'source_install'

# This module implements helpers that are used for resources
module SqliteInstall
  # This module exposes helpers to the client
  module Public
    def default_sqlite_version
      return '3300000'
    end

    def default_sqlite_directory
      # Must match source_install
      return "/opt/sqlite/#{default_sqlite_version}"
    end
  end

  # This module implements helpers that are used for resources
  module Install
    include Source::Install

    # Hooks for install

    def base_name(_new_resource)
      return 'sqlite'
    end

    def default_version(_new_resource)
      return default_sqlite_version
    end

    def archive_file_name(new_resource)
      return "#{base_name(new_resource)}-src-#{new_resource.version}.zip"
    end

    def download_base_url(new_resource)
      return "https://www.sqlite.org/#{new_resource.year}"
    end

    def archive_root_directory(new_resource)
      return "#{base_name(new_resource)}-src-#{new_resource.version}"
    end

    def extract_creates_file(_new_resource)
      return 'README.md'
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def configuration_command(new_resource)
      code = './configure'
      code += " --prefix=#{new_resource.install_directory}"
      code += " --exec-prefix=#{new_resource.install_directory}"
      code += ' --enable-memsys5'
      code += ' --enable-memsys3'
      code += ' --enable-fts3'
      code += ' --enable-fts4'
      code += ' --enable-fts5'
      code += ' --enable-json1'
      code += ' --enable-update-limit'
      code += ' --enable-geopoly'
      code += ' --enable-rtree'
      code += ' --enable-session'
      code += ' --enable-gcov'
      # Having troubles linking TCL library
      code += ' --disable-tcl' unless node['platform_family'] == 'debian'
      return code
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def install_creates_file(_new_resource)
      return 'lib/libsqlite3.so'
    end

    def install_command(_new_resource)
      return 'make install'
    end

    def post_install_logic(_new_resource)
      # Call custom logic here
    end

    # For common install code see source_install cookbook
  end
end

Chef::Provider.include(SqliteInstall::Public)
Chef::Recipe.include(SqliteInstall::Public)
Chef::Resource.include(SqliteInstall::Public)

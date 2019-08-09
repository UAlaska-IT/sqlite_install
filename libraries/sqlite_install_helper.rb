# frozen_string_literal: true

# This module implements helpers that are used for resources
module SqliteInstall
  # This module exposes helpers to the client
  module Public
  end
  # This module implements custom logic for this installer
  def Custom
  end
  # This module implements hooks into the base install
  def Hook
  end
  # This module implements helpers that are used for resources
  module Install
    # Hooks for install

    def base_name(_new_resource)
      return 'sqlite'
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
    def configuration_command(install_directory, _new_resource)
      code = './configure'
      code += " --prefix=#{install_directory}"
      code += " --exec-prefix=#{install_directory}"
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

    def post_build_logic(_install_directory, _new_resource)
      # Call custom logic here
    end

    # For common install code see base_install cookbook
  end
end

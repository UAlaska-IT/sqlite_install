# frozen_string_literal: true

# This module implements helpers that are used for resources
module SqliteInstall
  # This module implements helpers that are used for resources
  module Helper
    def path_to_download_directory(given_download_dir)
      return given_download_dir if given_download_dir

      return '/var/chef/cache'
    end

    def path_to_download_file(given_path, version)
      directory = path_to_download_directory(given_path)
      return File.join(directory, "sqlite-#{version}")
    end

    def sqlite_download_url(year, version)
      return "https://www.sqlite.org/#{year}/sqlite-src-#{version}.zip"
    end

    def download_archive(year, version, given_download_dir, given_build_dir)
      directory '/var/chef/cache' do
        not_if { given_download_dir && given_build_dir }
      end

      download_file = path_to_download_file(given_download_dir, version)

      remote_file download_file do
        source sqlite_download_url(year, version)
      end
    end

    def path_to_build_directory(given_path, version)
      return given_path if given_path

      return "/var/chef/cache/sqlite-#{version}"
    end

    def create_build_directory(given_path, version)
      build_directory = path_to_build_directory(given_path, version)

      directory build_directory do
        not_if { given_path }
      end

      return build_directory
    end

    def extract_archive(given_build_dir)
      build_directory = create_build_directory(given_build_dir, version)

      poise_archive download_file do
        destination build_directory
      end

      return build_directory
    end

    def build_configure_code(install_directory)
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

    def configure_build(install_directory, build_directory)
      code = build_configure_code(install_directory)

      bash 'Configure SQLite' do
        code code
        cwd build_directory
        creates File.join(build_directory, 'Makefile')
      end
    end

    def compile_and_install(version, build_directory)
      checksum_file 'SQLite Source Checksum' do
        source_path build_directory
        target_path "/var/chef/cache/sqlite-#{version}-checksum"
      end
      bash 'Compile and Install SQLite' do
        code 'make && make install'
        cwd build_directory
        # creates File.join(sqlite_lib_directory, 'libsqlite3.so')
        subscribes :run, 'checksum_file[SQLite Source Checksum]', :immediate
      end
    end

    def build_binary(version, install_directory, build_directory)
      configure_build(install_directory, build_directory)

      compile_and_install(version, build_directory)
    end

    def create_sqlite_install(new_resource)
      download_archive(
        new_resource.year,
        new_resource.version,
        new_resource.download_directory,
        new_resource.build_directory
      )

      build_directory = extract_archive(new_resource.build_directory)

      build_binary(new_resource.version, new_resource.install_directory, build_directory)
    end
  end
end

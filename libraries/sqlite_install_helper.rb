# frozen_string_literal: true

# This module implements helpers that are used for resources
module SqliteInstall
  # This module implements helpers that are used for resources
  module Helper
    BASE_NAME = 'sqlite'

    def path_to_download_directory(given_directory)
      return given_directory if given_directory

      directory '/var/chef'
      directory '/var/chef/cache'
      return '/var/chef/cache'
    end

    def archive_file_name(version)
      return "#{BASE_NAME}-src-#{version}.zip"
    end

    def path_to_download_file(given_directory, version)
      directory = path_to_download_directory(given_directory)
      file = File.join(directory, archive_file_name(version))
      return file
    end

    def download_url(year, version)
      return "https://www.sqlite.org/#{year}/#{archive_file_name(version)}"
    end

    def download_archive(given_download_dir, year, version)
      download_file = path_to_download_file(given_download_dir, version)
      url = download_url(year, version)
      remote_file download_file do
        source url
      end
      return download_file
    end

    def path_to_build_directory(given_directory, version)
      return given_directory if given_directory

      directory '/var/chef'
      directory '/var/chef/cache'
      return "/var/chef/cache/#{BASE_NAME}-#{version}"
    end

    def extract_archive(new_resource, build_directory, version)
      download_file = download_archive(new_resource.download_directory, new_resource.year, version)
      poise_archive download_file do
        destination build_directory
        user new_resource.owner
        group new_resource.group
      end
    end

    def path_to_install_directory(given_directory, version)
      return given_directory if given_directory

      directory "/opt/#{BASE_NAME}"
      directory "/opt/#{BASE_NAME}/#{version}"
      return "/opt/#{BASE_NAME}/#{version}"
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_config_code(install_directory)
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

    def configure_build(build_directory, install_directory)
      code = create_config_code(install_directory)
      bash 'Configure Build' do
        code code
        cwd build_directory
        creates File.join(build_directory, 'Makefile')
      end
    end

    def check_build_directory(build_directory, version)
      checksum_file 'Source Checksum' do
        source_path build_directory
        target_path "/var/chef/cache/#{BASE_NAME}-#{version}-checksum"
      end
    end

    def manage_bin_file(bin_file)
      file bin_file do
        action :nothing
        subscribes :delete, 'checksum_file[Source Checksum]', :immediate
      end
    end

    def make_build(build_directory, bin_file)
      bash 'Compile and Install' do
        code 'make && make install'
        cwd build_directory
        creates bin_file
      end
    end

    def compile_and_install(build_directory, install_directory, version)
      check_build_directory(build_directory, version)
      bin_file = File.join(install_directory, 'lib/libsqlite3.so')
      manage_bin_file(bin_file)
      make_build(build_directory, bin_file)
    end

    def build_binary(build_directory, given_install_directory, version)
      install_directory = path_to_install_directory(given_install_directory, version)
      configure_build(build_directory, install_directory)
      compile_and_install(build_directory, install_directory, version)
    end

    def create_install(new_resource)
      version = new_resource.version
      build_directory = path_to_build_directory(new_resource.build_directory, version)
      extract_archive(new_resource, build_directory, version)
      build_binary(build_directory, new_resource.install_directory, version)
    end
  end
end

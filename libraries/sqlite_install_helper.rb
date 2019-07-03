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

    def path_to_build_directory(given_directory)
      return given_directory if given_directory

      directory '/var/chef'
      directory '/var/chef/cache'
      return '/var/chef/cache'
    end

    def path_to_source_directory(build_directory)
      return File.join(build_directory, "#{BASE_NAME}-src-#{version}")
    end

    def clear_source_directory(build_directory, user, group)
      dir = path_to_source_directory(build_directory)
      bash 'Clear Archive' do
        code "rm -rf #{dir}\nmkdir #{dir}\nchmod #{user} #{dir}\nchgrp #{group} #{dir}"
        # Run as root so we blow it away if the owner changes
        action :nothing
        subscribes :run, 'checksum_file[Download Checksum]', :immediate
      end
    end

    def manage_source_directory(download_file, version, build_directory, user, group)
      checksum_file 'Download Checksum' do
        source_path download_file
        target_path "/var/chef/cache/#{BASE_NAME}-#{version}-dl-checksum"
      end
      clear_source_directory(build_directory, user, group)
    end

    def extract_download(download_file, build_directory, user, group)
      # Built-in archive_file requires Chef 15 and poise_archive is failing to exhibit idempotence on zip files
      dir = path_to_source_directory(build_directory)
      bash 'Extract Archive' do
        code "unzip -q #{download_file}\nchmod -R #{user} #{dir}\nchgrp -R #{group} #{dir}"
        cwd build_directory
        # Run as root in case it is installing in repo without write access
        creates File.join(dir, 'README.md')
      end
    end

    def extract_archive(new_resource, build_directory, user, group, version)
      download_file = download_archive(new_resource.download_directory, new_resource.year, version)
      manage_source_directory(download_file, version, build_directory, user, group)
      extract_download(download_file, build_directory, user, group)
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

    def configure_build(build_directory, install_directory, user, group)
      code = create_config_code(install_directory)
      dir = path_to_source_directory(build_directory)
      bash 'Configure Build' do
        code code
        cwd dir
        user user
        group group
        creates File.join(dir, 'Makefile')
      end
    end

    def check_build_directory(build_directory, version)
      checksum_file 'Source Checksum' do
        source_path path_to_source_directory(build_directory)
        target_path "/var/chef/cache/#{BASE_NAME}-#{version}-src-checksum"
      end
    end

    def manage_bin_file(bin_file)
      file bin_file do
        action :nothing
        manage_symlink_source false
        subscribes :delete, 'checksum_file[Source Checksum]', :immediate
      end
    end

    def make_build(build_directory, bin_file, user, group)
      bash 'Compile and Install' do
        code 'make && make install'
        cwd path_to_source_directory(build_directory)
        user user
        group group
        creates bin_file
      end
    end

    def compile_and_install(build_directory, install_directory, user, group, version)
      check_build_directory(build_directory, version)
      bin_file = File.join(install_directory, 'lib/libsqlite3.so')
      manage_bin_file(bin_file)
      make_build(build_directory, bin_file, user, group)
    end

    def build_binary(build_directory, given_install_directory, user, group, version)
      install_directory = path_to_install_directory(given_install_directory, version)
      configure_build(build_directory, install_directory, user, group)
      compile_and_install(build_directory, install_directory, user, group, version)
    end

    def create_install(new_resource)
      user = new_resource.owner
      group = new_resource.group
      version = new_resource.version
      build_directory = path_to_build_directory(new_resource.build_directory)
      extract_archive(new_resource, build_directory, user, group, version)
      build_binary(build_directory, new_resource.install_directory, user, group, version)
    end
  end
end

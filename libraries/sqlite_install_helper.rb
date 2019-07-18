# frozen_string_literal: true

# This module implements helpers that are used for resources
module SqliteInstall
  # This module implements helpers that are used for resources
  module Helper
    BASE_NAME = 'sqlite'
    EXTRACT_CREATES_FILE = 'README.md'
    BIN_CREATES_FILE = 'lib/libsqlite3.so'

    def archive_file_name(version)
      return "#{BASE_NAME}-src-#{version}.zip"
    end

    def download_url(version, new_resource)
      return "https://www.sqlite.org/#{new_resource.year}/#{archive_file_name(version)}"
    end

    def archive_root_directory(version)
      return "#{BASE_NAME}-src-#{version}"
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create_config_code(install_directory, _new_resource)
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

    def create_default_directories
      directory '/var/chef' do
        mode 0o755
        owner 'root'
        group 'root'
      end
      directory '/var/chef/cache' do
        mode 0o755
        owner 'root'
        group 'root'
      end
    end

    def path_to_download_directory(given_directory)
      return given_directory if given_directory

      create_default_directories
      return '/var/chef/cache'
    end

    def path_to_download_file(given_directory, version)
      directory = path_to_download_directory(given_directory)
      file = File.join(directory, archive_file_name(version))
      return file
    end

    def download_archive(version, owner, group, new_resource)
      download_file = path_to_download_file(new_resource.download_directory, version)
      url = download_url(version, new_resource)
      remote_file download_file do
        source url
        owner owner
        group group
      end
      return download_file
    end

    def path_to_build_directory(given_directory, version)
      base = archive_root_directory(version)
      return File.join(given_directory, base) if given_directory

      create_default_directories
      return File.join('/var/chef/cache', base)
    end

    def clear_source_directory(build_directory, user, group)
      dir = build_directory
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

    def extract_command(filename)
      return 'unzip -q' if filename.match?(/\.zip/)

      return 'tar xzf' if filename.match?(/\.tar\.gz/)

      raise "Archive not supported: #{filename}"
    end

    def code_for_extraction(download_file, build_directory, user, group)
      code = <<~CODE
        #{extract_command(download_file)} #{download_file}
        chown -R #{user} #{build_directory}
        chgrp -R #{group} #{build_directory}
      CODE
      return code
    end

    def extract_download(download_file, build_directory, user, group)
      # Built-in archive_file requires Chef 15 and poise_archive is failing to exhibit idempotence on zip files
      parent = File.dirname(build_directory)
      code = code_for_extraction(download_file, build_directory, user, group)
      bash 'Extract Archive' do
        code code
        cwd parent
        # Run as root in case it is installing in directory without write access
        creates File.join(build_directory, EXTRACT_CREATES_FILE)
      end
    end

    def extract_archive(new_resource, build_directory, user, group, version)
      download_file = download_archive(version, user, group, new_resource)
      manage_source_directory(download_file, version, build_directory, user, group)
      extract_download(download_file, build_directory, user, group)
    end

    def default_install_directory(version)
      return "/opt/#{BASE_NAME}/#{version}"
    end

    def create_opt_directories(version)
      directory "/opt/#{BASE_NAME}" do
        mode 0o755
        owner 'root'
        group 'root'
      end
      directory default_install_directory(version) do
        mode 0o755
        owner 'root'
        group 'root'
      end
    end

    def path_to_install_directory(given_directory, version)
      return given_directory if given_directory

      create_opt_directories(version)
      return default_install_directory(version)
    end

    def configure_build(build_directory, install_directory, user, group, new_resource)
      code = create_config_code(install_directory, new_resource)
      bash 'Configure Build' do
        code code
        cwd build_directory
        user user
        group group
        creates File.join(build_directory, 'Makefile')
      end
    end

    def check_build_directory(build_directory, version)
      checksum_file 'Source Checksum' do
        source_path build_directory
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

    def execute_build(build_directory, bin_file, user, group)
      bash 'Compile' do
        code 'make'
        cwd build_directory
        user user
        group group
        creates bin_file
      end
    end

    def execute_install(build_directory, bin_file)
      bash 'Install' do
        code 'make install'
        cwd build_directory
        # Run as root in case it is installing in directory without write access
        creates bin_file
      end
    end

    def recurse_command(path)
      return ' -R' if File.directory?(path)

      return ''
    end

    def command_for_file(install_directory, user, group, filename)
      path = File.join(install_directory, filename)
      recurse = recurse_command(path)
      return "\nchown#{recurse} #{user} #{path}\nchgrp#{recurse} #{group} #{path}"
    end

    def iterate_install_directory(install_directory, user, group)
      command = ''
      Dir.foreach(install_directory) do |filename|
        next if ['.', '..'].include?(filename)

        command += command_for_file(install_directory, user, group, filename)
      end
      return command
    end

    def build_permission_command(install_directory, user, group)
      ruby_block 'Build Children' do
        block do
          node.run_state['build_permission_command'] = iterate_install_directory(install_directory, user, group)
        end
        action :nothing
        subscribes :run, 'bash[Install]', :immediate
      end
    end

    # Some install scripts create artifacts in the source directory
    def set_src_permissions(build_directory, user, group)
      bash 'Set Config Permissions' do
        code "chown -R #{user} #{build_directory}\nchgrp -R #{group} #{build_directory}"
        action :nothing
        subscribes :run, 'bash[Install]', :immediate
      end
    end

    def set_install_permissions(build_directory, install_directory, user, group)
      build_permission_command(install_directory, user, group)
      bash 'Change Install Permissions' do
        code(lazy { node.run_state['build_permission_command'] })
        cwd install_directory
        action :nothing
        subscribes :run, 'bash[Install]', :immediate
      end
      set_src_permissions(build_directory, user, group)
    end

    def make_build(build_directory, install_directory, bin_file, user, group)
      execute_build(build_directory, bin_file, user, group)
      execute_install(build_directory, bin_file)
      set_install_permissions(build_directory, install_directory, user, group)
    end

    def compile_and_install(build_directory, install_directory, user, group, version)
      check_build_directory(build_directory, version)
      bin_file = File.join(install_directory, BIN_CREATES_FILE)
      manage_bin_file(bin_file)
      make_build(build_directory, install_directory, bin_file, user, group)
    end

    def build_binary(build_directory, user, group, version, new_resource)
      install_directory = path_to_install_directory(new_resource.install_directory, version)
      configure_build(build_directory, install_directory, user, group, new_resource)
      compile_and_install(build_directory, install_directory, user, group, version)
    end

    def create_install(new_resource)
      user = new_resource.owner
      group = new_resource.group
      version = new_resource.version
      build_directory = path_to_build_directory(new_resource.build_directory, version)
      extract_archive(new_resource, build_directory, user, group, version)
      build_binary(build_directory, user, group, version, new_resource)
    end
  end
end

# frozen_string_literal: true

include_recipe 'sqlite_install::default'

sqlite_installation 'All Defaults'

directory '/usr/local/sqlite-dl' do
  user 'root'
  group 'root'
  mode 0o755
end

directory '/usr/local/sqlite-bld' do
  user 'root'
  group 'root'
  mode 0o755
end

directory '/usr/local/sqlite' do
  user 'root'
  group 'root'
  mode 0o755
end

user 'bud' do
  shell '/bin/bash'
end

sqlite_installation 'No Defaults' do
  year '2018'
  version '3260000'
  download_directory '/usr/local/sqlite-dl'
  build_directory '/usr/local/sqlite-bld'
  install_directory '/usr/local/sqlite'
  owner 'bud'
  group 'bud'
end

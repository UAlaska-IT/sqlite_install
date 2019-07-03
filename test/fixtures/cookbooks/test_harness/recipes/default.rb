# frozen_string_literal: true

include_recipe 'sqlite_install::default'

sqlite_installation 'All Defaults'

directory '/usr/local/sqlite-dl'

directory '/usr/local/sqlite-bld'

directory '/usr/local/sqlite'

user 'bud'

sqlite_installation 'No Defaults' do
  year '2018'
  version '3.26.0'
  download_directory '/usr/local/sqlite-dl'
  build_directory '/usr/local/sqlite-bld'
  install_directory '/usr/local/sqlite'
  owner 'bud'
  group 'bud'
end

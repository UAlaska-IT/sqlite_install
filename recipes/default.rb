# frozen_string_literal: true

dev =
  if node['platform_family'] == 'debian'
    'dev'
  else
    'devel'
  end

apt_update 'Pre-Install Update' do
  action :update
end

package 'gcc'
package 'g++' if node['platform_family'] == 'debian'
package 'gcc-c++' unless node['platform_family'] == 'debian'
package 'make'

package "tcl-#{dev}"

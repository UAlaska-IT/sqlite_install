# frozen_string_literal: true

apt_update 'Pre-Install Update' do
  action :update
end

package 'gcc'
package 'g++' if node['platform_family'] == 'debian'
package 'gcc-c++' unless node['platform_family'] == 'debian'
package 'make'

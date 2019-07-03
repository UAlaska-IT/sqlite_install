# frozen_string_literal: true

package 'gcc'
package 'g++' if node['platform_family'] == 'debian'
package 'gcc-c++' unless node['platform_family'] == 'debian'
package 'make'

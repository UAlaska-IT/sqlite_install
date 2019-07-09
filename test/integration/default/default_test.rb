# frozen_string_literal: true

node = json('/opt/chef/run_record/last_chef_run_node.json')['automatic']

dev =
  if node['platform_family'] == 'debian'
    'dev'
  else
    'devel'
  end

describe package('gcc') do
  it { should be_installed }
end

describe package('g++') do
  it { should be_installed } if node['platform_family'] == 'debian'
end

describe package('gcc-c++') do
  it { should be_installed } unless node['platform_family'] == 'debian'
end

describe package('make') do
  it { should be_installed }
end

describe package('unzip') do
  it { should be_installed }
end

describe package("tcl-#{dev}") do
  it { should be_installed }
end

name 'my_workstation'
maintainer 'The Authors'
maintainer_email 'you@example.com'
license 'all_rights'
description 'Installs/Configures my_workstation'
long_description 'Installs/Configures my_workstation'
version '0.1.0'

%w(debian ubuntu).each do |platform|
  supports platform
end

# cookbook 'chef-sugar'
depends 'chef-sugar'

depends 'apt'
depends 'docker', '~> 2.0'
depends 'ntp'
depends 'openssh', '~> 2.0.0'
depends 'poise-python', '~> 1.5.1'
depends 'ruby_build', '~> 1.0.0'
depends 'ruby_rbenv', '~> 1.1.0'
depends 'sudo'
depends 'system'
depends 'tarball'
depends 'vagrant', '~> 0.6.0'

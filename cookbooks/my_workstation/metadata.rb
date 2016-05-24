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

depends 'apt'
depends 'docker', '~> 2.0'
depends 'openssh', '~> 2.0.0'
depends 'poise-python', '~> 1.3.0'
depends 'ruby_build', '~> 0.8.0'
depends 'ruby_rbenv', '~> 1.0.1'
depends 'sudo'
depends 'system'
depends 'tarball'
depends 'vagrant', '~> 0.5.0'

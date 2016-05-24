#-----------------------------------------------------------------------------------------------------------------------
# APT General

default['apt'].tap do |apt|
  # When true, force the default recipe to run apt-get update at compile time.
  apt['compile_time_update'] = false
  # Minimum delay (in seconds) beetween two actual executions of 'apt-get update' by the
  # execute[apt-get-update-periodic] resource, default is '86400' (24 hours).
  apt['periodic_update_min_delay'] = 86400
  # Consider recommended packages as a dependency for installing. Default: true.
  apt['confd']['install_recommends'] = true
  # Consider suggested packages as a dependency for installing. Default: false.
  apt['confd']['install_suggests'] = false
end

#-----------------------------------------------------------------------------------------------------------------------
# APT Unattended Upgrades

default['apt']['unattended_upgrades'].tap do |upgrades|
  # Enables unattended upgrades, default is false.
  upgrades['enable'] = true
  # Automatically update package list (apt-get update) daily, default is true.
  upgrades['update_package_lists'] = true
  # Automatically install security updates.
  upgrades['allowed_origins'] << '${distro_id}:${distro_codename}-security' # "origin=Ubuntu,archive=trusty-security"
  # An array of package which should never be automatically upgraded, defaults to none.
  upgrades['package_blacklist'] = []
  # Attempts to repair dpkg state with 'dpkg --force-confold --configure -a' if it exits uncleanly, defaults to false
  # (contrary to the unattended-upgrades default).
  upgrades['auto_fix_interrupted_dpkg'] = true
  # Split the upgrade into the smallest possible chunks. This makes the upgrade a bit slower but it has the benefit that
  # shutdown while a upgrade is running is possible (with a small delay). Defaults to false.
  upgrades['minimal_steps'] = true
  # Install upgrades when the machine is shutting down instead of doing it in the background while the machine is
  # running. This will (obviously) make shutdown slower. Defaults to false.
  upgrades['install_on_shutdown'] = false
  # Send email to this address for problems or packages upgrades. Defaults to no email.
  upgrades['mail'] = ''
  # If set, email will only be sent on upgrade errors; else an email will be sent after each upgrade. Defaults to true.
  upgrades['mail_only_on_error'] = true
  # Do automatic removal of new unused dependencies after the upgrade. Defaults to false.
  upgrades['remove_unused_dependencies'] = true
  # Automatically reboots without confirmation if a restart is required after the upgrade. Defaults to false.
  upgrades['automatic_reboot'] = false
  # Limits the bandwidth used by apt to download packages. Value given as an int in kb/sec. Defaults to nil (no limit).
  upgrades['dl_limit'] = nil
  # Wait a random number of seconds up to this value before running daily periodic apt actions. System default is 1800
  # seconds (30 minutes).
  upgrades['random_sleep]'] = 1800
end

#-----------------------------------------------------------------------------------------------------------------------
# System Settings

# Sets the timezone via the "system" cookbook.
default['system']['timezone'] = 'America/Chicago'

#-----------------------------------------------------------------------------------------------------------------------
# Sudoers!

# Groups to enable sudo access (default: [ "sysadmin" ]).
default['authorization']['sudo'].tap do |sudo|
  sudo['groups'] = [
    'admin',
    'sudo'
  ]
  # Users to enable sudo access (default: []).
  sudo['users'] = [
    'myuser'
  ]
  # Use passwordless sudo (default: false).
  sudo['passwordless'] = true
  # Include and manage /etc/sudoers.d (default: false).
  sudo['include_sudoers_d'] = true
  # Preserve SSH_AUTH_SOCK when sudoing (default: false).
  sudo['agent_forwarding']
  # Array of Defaults entries to configure in /etc/sudoers.
  sudo['sudoers_defaults'] = [
    'env_reset',
    'mail_badpass',
    'secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"',
  ]
  # Whether to permit preserving of environment with sudo -E (default: false).
  sudo['setenv'] = false
end

#-----------------------------------------------------------------------------------------------------------------------
# OpenSSH!

# ssh config group
default['openssh']['client'].tap do |client|
  client['host'] = '*'

  # Workaround for CVE-2016-0777 and CVE-2016-0778.
  # Older versions of RHEL should not receive this directive
  client['use_roaming'] = 'no' unless node['platform_family'] == 'rhel' && node['platform_version'].to_i < 7
  # client['forward_agent'] = 'no'
  # client['forward_x11'] = 'no'
  client['rhosts_rsa_authentication'] = 'no'
  # client['rsa_authentication'] = 'yes'
  # client['password_authentication'] = 'yes'
  client['host_based_authentication'] = 'no'
  # client['gssapi_authentication'] = 'no'
  # client['gssapi_delegate_credentials'] = 'no'
  # client['batch_mode'] = 'no'
  # client['check_host_ip'] = 'yes'
  # client['address_family'] = 'any'
  # client['connect_timeout'] = '0'
  # client['strict_host_key_checking'] = 'ask'
  # client['identity_file'] = '~/.ssh/identity'
  # client['identity_file_rsa'] = '~/.ssh/id_rsa'
  # client['identity_file_dsa'] = '~/.ssh/id_dsa'
  # client['port'] = '22'
  # client['protocol'] = [ '2 1' ]
  # client['cipher'] = '3des'
  # client['ciphers'] = [ 'aes128-ctr aes192-ctr aes256-ctr arcfour256 arcfour128 aes128-cbc 3des-cbc' ]
  # client['macs'] = [ 'hmac-md5 hmac-sha1 umac-64@openssh.com hmac-ripemd160' ]
  # client['escape_char'] = '~'
  # client['tunnel'] = 'no'
  # client['tunnel_device'] = 'any:any'
  # client['permit_local_command'] = 'no'
  # client['visual_host_key'] = 'no'
  # client['proxy_command'] = 'ssh -q -W %h:%p gateway.example.com'
end

# sshd config group
default['openssh']['server'].tap do |server|
  server['port'] = '22'

  # Use these options to restrict which interfaces/protocols sshd will bind to.
  # server['address_family'] = 'any'
  # server['listen_address'] = [ '0.0.0.0 ::' ]
  server['listen_address'] = %w(127.0.0.1)

  server['protocol'] = '2'

  # HostKeys for protocol version 2.
  server['host_key'] = %w{
    /etc/ssh/ssh_host_rsa_key
    /etc/ssh/ssh_host_dsa_key
    /etc/ssh/ssh_host_ecdsa_key
    /etc/ssh/ssh_host_ed25519_key
  }

  # Privilege Separation is turned on for security.
  server['use_privilege_separation'] = 'yes'

  # Lifetime and size of ephemeral version 1 server key.
  server['key_regeneration_interval'] = '1h'
  server['server_key_bits'] = '1024'

  # Logging.
  server['syslog_facility'] = 'AUTH'
  server['log_level'] = 'INFO'

  # Authentication.
  server['login_grace_time'] = '2m'
  # Google by default on GCE sets this to 'without-password'.
  server['permit_root_login'] = 'without-password'
  server['strict_modes'] = 'yes'
  # server['max_auth_tries'] = '6'
  # server['max_sessions'] = '10'
  server['r_s_a_authentication'] = 'yes'
  server['pubkey_authentication'] = 'yes'
  # server['authorized_keys_file'] = '%h/.ssh/authorized_keys'

  # Don't read the user's ~/.rhosts and ~/.shosts files.
  server['ignore_rhosts'] = 'yes'
  # For this to work you will also need host keys in /etc/ssh_known_hosts.
  server['rhosts_r_s_a_authentication'] = 'no'
  # Similar for protocol version 2.
  server['host_based_authentication'] = 'no'
  # Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication.
  # server['ignore_user_known_hosts'] = 'yes'

  # To enable empty passwords, change to yes (NOT RECOMMENDED).
  server['permit_empty_passwords'] = 'no'
  # When set to 'no', disables tunnelled clear text passwords.
  server['password_authentication'] = 'no'
  # Change to yes to enable challenge-response passwords (beware issues with some PAM modules and threads).
  server['challenge_response_authentication'] = 'no'

  # Kerberos options.
  # server['kerberos_authentication'] = 'no'
  # server['kerberos_or_localpasswd'] = 'yes'
  # server['kerberos_ticket_cleanup'] = 'yes'
  # server['kerberos_get_afs_token'] = 'no'

  # GSSAPI options.
  # server['gssapi_authentication'] = 'no'
  # server['gssapi_clean_up_credentials'] = 'yes'

  # Set this to 'yes' to enable PAM authentication, account processing, and session processing. If this is enabled, PAM
  # authentication will be allowed through the ChallengeResponseAuthentication and PasswordAuthentication.  Depending on
  # your PAM configuration, PAM authentication via ChallengeResponseAuthentication may bypass the setting of
  # "PermitRootLogin without-password". If you just want the PAM account and session checks to run without PAM
  # authentication, then enable this but set PasswordAuthentication and ChallengeResponseAuthentication to 'no'.
  server['use_p_a_m'] = 'yes' unless platform_family?('smartos')

  # server['allow_agent_forwarding'] = 'yes'
  # server['allow_tcp_forwarding'] = 'yes'
  # server['gateway_ports'] = 'no'
  server['x11_forwarding'] = 'no'
  # server['x11_display_offset'] = '10'
  # server['x11_use_localhost'] = 'yes'
  server['print_motd'] = 'no'
  server['print_last_log'] = 'yes'
  server['t_c_p_keep_alive'] = 'yes'
  # server['use_login'] = 'no'
  # server['permit_user_environment'] = 'no'
  # server['compression'] = 'delayed'

  # Google Compute Engine times out connections after 10 minutes of inactivity.
  # Keep alive ssh connections by sending a packet every 2 minutes.
  server['client_alive_interval'] = '2m'

  # server['client_alive_count_max'] = '3'
  # Prevent reverse DNS lookups.
  server['use_dns'] = 'no'
  # server['pid_file'] = '/var/run/sshd.pid'
  # server['max_startups'] = '10'
  # server['permit_tunnel'] = 'no'
  # server['chroot_directory'] = 'none'
  # server['banner'] = 'none'

  # Allow client to pass locale environment variables.
  server['accept_env'] = 'LANG LC_*'

  server['subsystem'] = 'sftp /usr/lib/openssh/sftp-server'

  # server['match'] = {}
end

#-----------------------------------------------------------------------------------------------------------------------
# Python

default['poise-python']['options']['pip_version'] = true

#-----------------------------------------------------------------------------------------------------------------------
# Ruby.

default['rbenv'].tap do |rbenv|
  # Install Ruby 2.3.0 and make it the default.
  rbenv['rubies'] = [
    '2.3.0'
  ]

  rbenv['gems'] = {
    '2.3.0' => [
      { 'name'    => 'rubocop' }
    ]
  }
end

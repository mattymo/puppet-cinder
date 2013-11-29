# == Class: cinder::backends
#
# Class to set the enabled_backends list
#
# === Parameters
#
# [use_syslog]
#   Use syslog for logging.
#   (Optional) Defaults to false.
#
# [log_facility]
#   Syslog facility to receive log lines.
#   (Optional) Defaults to LOG_USER.
#
# [log_level]
#   Minimal logging threshold used if debug and verbose are false.
#   (Optional) Defaults to 'WARNING'.
#
# Author: Matthew Mosesohn <mmosesohn@mirantis.com>
class cinder::logging (
  $use_syslog    = false,
  $debug         = false,
  $verbose       = false,
  $log_dir       = '/var/log/cinder',
  $log_facility  = 'LOG_USER',
  $log_level     = 'WARNING',
) {

  include cinder::params

  if $use_syslog {
    cinder_config {
      'DEFAULT/log_config': value => '/etc/cinder/logging.conf';
      'DEFAULT/log_file':   ensure=> absent;
      'DEFAULT/log_dir':    ensure=> absent;
      'DEFAULT/logfile':    ensure=> absent;
      'DEFAULT/logdir':     ensure=> absent;
      'DEFAULT/use_syslog': value => true;
      'DEFAULT/syslog_log_facility': value =>  $log_facility;
    }
    file { 'cinder-logging.conf':
      content => template('cinder/logging.conf.erb'),
      path    => '/etc/cinder/logging.conf',
      require => File[$::cinder::params::cinder_conf],
    }
  }
  else {
    #Use local logging to $log_dir
    cinder_config {
      'DEFAULT/log_config': ensure => absent;
      'DEFAULT/use_syslog': value => false;
      'DEFAULT/use_stderr': ensure => absent;
      'DEFAULT/logdir':value => $log_dir;
      'DEFAULT/logging_context_format_string':
        value => '%(asctime)s %(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s] %(instance)s %(message)s';
      'DEFAULT/logging_default_format_string':
        value => '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s';
    }
    # might be used for stdout logging instead, if configured
    file { 'cinder-logging.conf':
      content => template('cinder/logging.conf-nosyslog.erb'),
      path    => '/etc/cinder/logging.conf',
      require => File[$::cinder::params::cinder_conf],
    }
  }
  # We must notify services to apply new logging rules
  File['cinder-logging.conf'] ~> Service<| title == $::cinder::params::api_service |>
  File['cinder-logging.conf'] ~> Service<| title == $::cinder::params::volume_service |>
  File['cinder-logging.conf'] ~> Service<| title == $::cinder::params::scheduler_service |>

  if $log_dir {
    file { $log_dir:
      ensure => directory,
      owner  => 'cinder',
      group  => 'cinder',
    }
  }
}

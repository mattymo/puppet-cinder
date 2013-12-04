# == Class: cinder::backends
#
# Class to set the enabled_backends list
#
# === Parameters
#
# [use_syslog]
#   Use syslog for logging (or local logging if false)
#   (Optional) Defaults to false.
#
# [log_facility]
#   Syslog facility to receive log lines.
#   Applies only when using syslog.
#   (Optional) Defaults to LOG_USER.
#
# [log_dir]
#   Directory to store logs when not using syslog.
#   (Optional) Defaults to '/var/log/cinder'.
#
# [log_level]
#   Minimal logging threshold used if debug and verbose are false.
#   Applies to syslog and local logging.
#   (Optional) Defaults to 'WARNING'.
#
# [log_context_string_format]
#   Format string to use for log messages with context
#   (Optional) Defaults to false
#
# [log_default_string_format]
#   Format string to use for log messages without context
#   (Optional) Defaults to false
# Author: Matthew Mosesohn <mmosesohn@mirantis.com>
class cinder::logging (
  $use_syslog                = false,
  $debug                     = false,
  $verbose                   = false,
  $log_dir                   = '/var/log/cinder',
  $log_facility              = 'LOG_USER',
  $log_level                 = 'WARNING',
  $log_context_string_format = false,
  $log_default_string_format = false,
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
    file { $::cinder::params::cinder_log_conf:
      content => template('cinder/logging.conf.erb'),
      require => File[$::cinder::params::cinder_conf],
    }
  }
  else {
    #Use local logging to $log_dir
    cinder_config {
      'DEFAULT/log_config': ensure => absent;
      'DEFAULT/use_syslog': value  => false;
      'DEFAULT/use_stderr': ensure => absent;
      'DEFAULT/logdir':     value  => $log_dir;
    }
    # might be used for stdout logging instead, if configured
    file { 'cinder-logging.conf':
      content => template('cinder/logging.conf-nosyslog.erb'),
      path    => '/etc/cinder/logging.conf',
      require => File[$::cinder::params::cinder_conf],
    }
  }
  # We must notify services to apply new logging rules
  File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::api_service |>
  File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::volume_service |>
  File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::scheduler_service |>

  if $log_context_string_format {
     cinder_config {
      'DEFAULT/logging_context_format_string':
        value => $log_context_string_format;
     }
  } else {
     cinder_config {
      'DEFAULT/logging_context_format_string':
        ensure => absent;
     }
  }
  if $log_default_string_format {
    cinder_config {
      'DEFAULT/logging_default_format_string':
        value => $log_default_string_format;
    }
  } else {
    cinder_config {
      'DEFAULT/logging_context_format_string':
        ensure => absent;
     }


  if $log_dir {
    file { $log_dir:
      ensure => directory,
      owner  => 'cinder',
      group  => 'cinder',
    }
  }
}

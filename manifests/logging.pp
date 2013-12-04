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
#   Directory for cinder to use for logs if syslog is false
#   (Optional) Defaults to '/var/log/cinder/'.
#
# [debug]
#   Use debug logging (DEBUG severity and above).
#   You should address this variable in logging config template, if any.
#   (Optional) Defaults to false.
#
# [verbose]
#   Use verbose logging (INFO severity and above).
#   You should address this variable in logging config template, if any.
#   (Optional) Defaults to false.
#
# [log_level]
#   Minimal logging threshold used if debug and verbose are false.
#   Applies to syslog and local logging.
#   You should address this variable in logging config template, if any.
#   (Optional) Defaults to 'WARNING'.
#
# [logging_context_format_string_local]
#   Format string to use for log messages with context for local logging, e.g.:
#   '%(asctime)s %(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s] %(instance)s %(message)s'
#   (Optional) Defaults to false.  
#
# [logging_default_format_string_local]
#   Format string to use for log messages without context for local logging, e.g.:
#   '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s
#   (Optional) Defaults to false.
#
# [log_config_local]
#   Custom template file name for python logging config used for local logging, e.g.: logging_local.conf.erb
#   To use custom logging config, just create an erb template and pass its name here
#   (Optional) Defaults to false.
#
# [logging_context_format_string_syslog]
#   Format string to use for log messages with context for syslog logging
#   (Optional) Defaults to false.  
#
# [logging_default_format_string_syslog]
#   Format string to use for log messages without context for syslog logging
#   (Optional) Defaults to false.
#
# [log_config_syslog]
#   Custom template file name for python logging config used for syslog logging
#   To use custom logging config, just create an erb template and pass its name here
#   (Optional) Defaults to false.
#
# Authors: Matthew Mosesohn <mmosesohn@mirantis.com>
#          Bogdan Dobrelya <bdobrelia@mirantis.com>
class cinder::logging (
  $use_syslog                            = false,
  $debug                                 = false,
  $verbose                               = false,
  $log_dir                               = '/var/log/cinder',
  $log_facility                          = 'LOG_USER',
  $log_level                             = 'WARNING',
  $log_config_local                      = false,
  $logging_context_format_string_local   = false,
  $logging_default_format_string_local   = false,
  $log_config_syslog                     = false,
  $logging_context_format_string_syslog  = false,
  $logging_default_format_string_syslog  = false,
) {

  include cinder::params

  if $use_syslog {
    cinder_config {
      'DEFAULT/log_file':            ensure => absent;
      'DEFAULT/log_dir':             ensure => absent;
      'DEFAULT/logfile':             ensure => absent;
      'DEFAULT/logdir':              ensure => absent;
      'DEFAULT/use_syslog':          value  => true;
      'DEFAULT/syslog_log_facility': value  =>  $log_facility;
    }
    if $log_config_syslog {
      file { $::cinder::params::cinder_log_conf:
        content => template("cinder/${log_config_syslog}"),
        require => File[$::cinder::params::cinder_conf],
      }
      cinder_config {
        'DEFAULT/log_config': value => $::cinder::params::cinder_log_conf
      }
    }
    if $logging_context_format_string_syslog {
      cinder_config {
        'DEFAULT/logging_context_format_string': value => $logging_context_format_string_syslog
      }
    }
    if $logging_default_format_string_syslog {
      cinder_config {
        'DEFAULT/logging_default_format_string': value => $logging_default_format_string_syslog
      }
    if $logging_default_format_string_syslog {
      cinder_config {
        'DEFAULT/logging_default_format_string': value => $logging_default_format_string_syslog
      }
    }
  }
  else {
    #Use local logging to $log_dir
    cinder_config {
      'DEFAULT/log_config': ensure => absent;
      'DEFAULT/use_syslog': value  => false;
      'DEFAULT/use_stderr': ensure => absent;
      'DEFAULT/log_dir':    value  => $log_dir;
    }
    if $log_config_local {
      file { $::cinder::params::cinder_log_conf:
        content => template("cinder/${log_config_local}"),
        require => File[$::cinder::params::cinder_conf],
      }
      cinder_config {
        'DEFAULT/log_config': value => $::cinder::params::cinder_log_conf
      }
    }
    if $logging_context_format_string_local {
      cinder_config {
        'DEFAULT/logging_context_format_string': value => $logging_context_format_string_local
      }
    }
    if $logging_default_format_string_local {
      cinder_config {
        'DEFAULT/logging_default_format_string': value => $logging_default_format_string_local
      }
    }
  }
  # We must notify services to apply new logging rules
  File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::api_service |>
  File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::volume_service |>
  File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::scheduler_service |>

  if !($log_context_string_format_syslog or $log_context_string_format_local) {
     cinder_config {
      'DEFAULT/logging_context_format_string':
        ensure => absent;
     }
  }
  if !($log_default_string_format_syslog or $log_default_string_format_local) {
    cinder_config {
      'DEFAULT/logging_default_format_string':
        ensure => absent;
     }
  }

  if $log_dir {
    file { $log_dir:
      ensure => directory,
      owner  => 'cinder',
      group  => 'cinder',
    }
  }
}

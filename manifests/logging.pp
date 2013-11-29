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
# [logging_context_format_string]
#   Format string to use for log messages with context, e.g.:
#   '%(asctime)s %(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s] %(instance)s %(message)s'
#   (Optional) Defaults to false.
#
# [logging_default_format_string]
#   Format string to use for log messages without context, e.g.:
#   '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s'
#   (Optional) Defaults to false.
#
# [log_config]
#   Custom template file name for python logging config, e.g.: logging.conf.erb
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
  $log_config                            = false,
  $logging_context_format_string         = false,
  $logging_default_format_string         = false
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
  }
  else {
    #Use local logging to $log_dir
    cinder_config {
      'DEFAULT/use_syslog':        value  => false;
      'DEFAULT/use_stderr':        ensure => absent;
      'DEFAULT/log_dir':           value  => $log_dir;
    }
  }

  if $log_config {
    file { $::cinder::params::cinder_log_conf:
      content => template("cinder/${log_config}"),
      require => File[$::cinder::params::cinder_conf],
      owner   => 'cinder',
      group   => 'cinder',
      mode    => '0600',
    }
    cinder_config {
      'DEFAULT/log_config_append': value => $::cinder::params::cinder_log_conf
    }
    # We must notify services to apply new logging rules
    File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::api_service |>
    File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::volume_service |>
    File[$::cinder::params::cinder_log_conf] ~> Service<| title == $::cinder::params::scheduler_service |>
  }

  if $logging_context_format_string {
    cinder_config {
      'DEFAULT/logging_context_format_string':
        value => $logging_context_format_string;
    }
  }

  if $logging_default_format_string {
    cinder_config {
      'DEFAULT/logging_default_format_string':
        value => $logging_default_format_string;
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

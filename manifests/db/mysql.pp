#
class cinder::db::mysql (
  $password,
  $dbname        = 'cinder',
  $user          = 'cinder',
  $host          = '127.0.0.1',
  $allowed_hosts = undef,
  $charset       = 'latin1',
  $cluster_id    = 'localzone'
) {

  include cinder::params

  Class['mysql::server'] -> Class['cinder::db::mysql']
  #if $::osfamily == "Debian" {
  #  Class['cinder::db::mysql'] -> Package['cinder-api']
  #}
  Class['cinder::db::mysql'] -> Exec<| title == 'cinder-manage db_sync' |>
  Database[$dbname] ~> Service<| title == 'cinder-manage db_sync' |>

  Class['cinder::db::mysql'] -> Service<| title == 'cinder-scheduler' |>
  Class['cinder::db::mysql'] -> Service<| title == 'cinder-volume' |>
  Class['cinder::db::mysql'] -> Service<| title == 'cinder-api' |>

  mysql::db { $dbname:
    user         => $user,
    password     => $password,
    host         => $host,
    charset      => $charset,
    require      => Class['mysql::server'],
  }
  # Check allowed_hosts to avoid duplicate resource declarations
  if is_array($allowed_hosts) and delete($allowed_hosts,$host) != [] {
    $real_allowed_hosts = delete($allowed_hosts,$host)
  } elsif is_string($allowed_hosts) and ($allowed_hosts != $host) {
    $real_allowed_hosts = $allowed_hosts
  }

  if $real_allowed_hosts {
    # TODO this class should be in the mysql namespace
    cinder::db::mysql::host_access { $real_allowed_hosts:
      user      => $user,
      password  => $password,
      database  => $dbname,
    }
  }

}

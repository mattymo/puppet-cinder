#
# class for installing rabbitmq server for cinder
#
#
class cinder::rabbitmq(
  $userid       = 'guest',
  $password     = 'guest',
  $port         = '5672',
  $virtual_host = '/',
  $enabled      = true
) {

  # only configure cinder after the queue is up
  Class['rabbitmq::service'] -> Anchor<| title == 'cinder-start' |>

  if ($enabled) {
    if $userid == 'guest' {
      $delete_guest_user = false
    } else {
      $delete_guest_user = true
      rabbitmq_user { $userid:
        admin    => true,
        password => $password,
        provider => 'rabbitmqctl',
        require  => Class['rabbitmq::server'],
      }
      # I need to figure out the appropriate permissions
      rabbitmq_user_permissions { "${userid}@${virtual_host}":
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
      }->Anchor<| title == 'cinder-start' |>
    }
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  class { 'rabbitmq::server':
    service_ensure    => $service_ensure,
    port              => $port,
    delete_guest_user => $delete_guest_user,
  }

  if ($enabled) {
    rabbitmq_vhost { $virtual_host:
      provider => 'rabbitmqctl',
      require  => Class['rabbitmq::server'],
    }
  }
}

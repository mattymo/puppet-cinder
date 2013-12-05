require 'spec_helper'
describe 'cinder' do
  let :req_params do
    {:rabbit_password => 'guest', :sql_connection => 'mysql://user:password@host/database'}
  end

  let :facts do
    {:osfamily => 'Debian'}
  end

  describe 'with only required params' do
    let :params do
      req_params
    end

    it { should contain_class('cinder::params') }

    it 'should contain default config' do
      should contain_cinder_config('DEFAULT/rpc_backend').with(
        :value => 'cinder.openstack.common.rpc.impl_kombu'
      )
      should contain_cinder_config('DEFAULT/control_exchange').with(
        :value => 'openstack'
      )
      should contain_cinder_config('DEFAULT/rabbit_password').with(
        :value => 'guest',
        :secret => true
      )
      should contain_cinder_config('DEFAULT/rabbit_host').with(
        :value => '127.0.0.1'
      )
      should contain_cinder_config('DEFAULT/rabbit_port').with(
        :value => '5672'
      )
      should contain_cinder_config('DEFAULT/rabbit_hosts').with(
        :value => '127.0.0.1:5672'
      )
      should contain_cinder_config('DEFAULT/rabbit_ha_queues').with(
        :value => false
      )
      should contain_cinder_config('DEFAULT/rabbit_virtual_host').with(
        :value => '/'
      )
      should contain_cinder_config('DEFAULT/rabbit_userid').with(
        :value => 'guest'
      )
      should contain_cinder_config('DEFAULT/sql_connection').with(
        :value  => 'mysql://user:password@host/database',
        :secret => true
      )
      should contain_cinder_config('DEFAULT/sql_idle_timeout').with(
        :value => '3600'
      )
      should contain_cinder_config('DEFAULT/verbose').with(
        :value => false
      )
      should contain_cinder_config('DEFAULT/debug').with(
        :value => false
      )
      should contain_cinder_config('DEFAULT/api_paste_config').with(
        :value => '/etc/cinder/api-paste.ini'
      )
    end

    #FIXME : according to logging.pp should be absent for defaults!
    it 'should not contain default config' do
      pending('FIXME : according to logging.pp should be absent for defaults!')
      should_not contain_cinder_config('DEFAULT/logging_context_format_string')
      should_not contain_cinder_config('DEFAULT/logging_default_format_string')
      should_not contain_cinder_config('DEFAULT/log_config_append')
      should_not contain_cinder_config('DEFAULT/log_config')
    end

    it { should contain_file('/etc/cinder/cinder.conf').with(
      :owner   => 'cinder',
      :group   => 'cinder',
      :mode    => '0600',
      :require => 'Package[cinder]'
    ) }

    it { should contain_file('/etc/cinder/api-paste.ini').with(
      :owner   => 'cinder',
      :group   => 'cinder',
      :mode    => '0600',
      :require => 'Package[cinder]'
    ) }

  end
  describe 'with modified rabbit_hosts' do
    let :params do
      req_params.merge({'rabbit_hosts' => ['rabbit1:5672', 'rabbit2:5672']})
    end

    it 'should contain many' do
      should_not contain_cinder_config('DEFAULT/rabbit_host')
      should_not contain_cinder_config('DEFAULT/rabbit_port')
      should contain_cinder_config('DEFAULT/rabbit_hosts').with(
        :value => 'rabbit1:5672,rabbit2:5672'
      )
      should contain_cinder_config('DEFAULT/rabbit_ha_queues').with(
        :value => true
      )
    end
  end

  describe 'with a single rabbit_hosts entry' do
    let :params do
      req_params.merge({'rabbit_hosts' => ['rabbit1:5672']})
    end

    it 'should contain many' do
      should_not contain_cinder_config('DEFAULT/rabbit_host')
      should_not contain_cinder_config('DEFAULT/rabbit_port')
      should contain_cinder_config('DEFAULT/rabbit_hosts').with(
        :value => 'rabbit1:5672'
      )
      should contain_cinder_config('DEFAULT/rabbit_ha_queues').with(
        :value => true
      )
    end
  end

  describe 'with qpid rpc supplied' do

    let :params do
      {
        :sql_connection      => 'mysql://user:password@host/database',
        :qpid_password       => 'guest',
        :rpc_backend         => 'cinder.openstack.common.rpc.impl_qpid'
      }
    end

    it { should contain_cinder_config('DEFAULT/sql_connection').with_value('mysql://user:password@host/database') }
    it { should contain_cinder_config('DEFAULT/rpc_backend').with_value('cinder.openstack.common.rpc.impl_qpid') }
    it { should contain_cinder_config('DEFAULT/qpid_hostname').with_value('localhost') }
    it { should contain_cinder_config('DEFAULT/qpid_port').with_value('5672') }
    it { should contain_cinder_config('DEFAULT/qpid_username').with_value('guest') }
    it { should contain_cinder_config('DEFAULT/qpid_password').with_value('guest').with_secret(true) }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect').with_value(true) }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_timeout').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_limit').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_interval_min').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_interval_max').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_reconnect_interval').with_value('0') }
    it { should contain_cinder_config('DEFAULT/qpid_heartbeat').with_value('60') }
    it { should contain_cinder_config('DEFAULT/qpid_protocol').with_value('tcp') }
    it { should contain_cinder_config('DEFAULT/qpid_tcp_nodelay').with_value(true) }

  end

  describe 'with syslog disabled' do
    let :params do
      req_params.merge({
        :log_dir => '/var/log/cinder',
      })
    end

    it { should contain_cinder_config('DEFAULT/use_syslog').with_value(false) }
    it { should contain_cinder_config('DEFAULT/log_dir').with_value('/var/log/cinder') }
    it { should_not contain_cinder_config('DEFAULT/logdir') }
    it { should_not contain_cinder_config('DEFAULT/logfile') }
    it { should_not contain_cinder_config('DEFAULT/log_file') }
  end

  describe 'with syslog enabled' do
    let :params do
      req_params.merge({
        :use_syslog   => 'true',
      })
    end

    it { should contain_cinder_config('DEFAULT/use_syslog').with_value(true) }
    it { should contain_cinder_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
    it { should_not contain_cinder_config('DEFAULT/use_stderr') }
  end

  describe 'with syslog enabled and custom settings' do
    let :params do
      req_params.merge({
        :use_syslog   => 'true',
        :log_facility => 'LOG_LOCAL0'
     })
    end

    it { should contain_cinder_config('DEFAULT/use_syslog').with_value(true) }
    it { should contain_cinder_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0') }
  end

  describe 'with custom context format string' do
    let :params do
      req_params.merge({
        :logging_context_format_string   => '%(asctime)s %(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s] %(instance)s %(message)s',
     })
    end

    it { should contain_cinder_config('DEFAULT/logging_context_format_string').with_value(
      '%(asctime)s %(levelname)s %(name)s [%(request_id)s %(user_id)s %(project_id)s] %(instance)s %(message)s'
    ) }
  end

  describe 'with custom default format string' do
    let :params do
      req_params.merge({
        :logging_default_format_string  => '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s',
     })
    end

    it { should contain_cinder_config('DEFAULT/logging_default_format_string').with_value(
      '%(asctime)s %(levelname)s %(name)s [-] %(instance)s %(message)s'
    ) }
  end

  describe 'with custom log config template name' do
    let :params do
      req_params.merge({
        :log_config  => 'logging_syslog.conf.erb',
     })
    end

    it { should contain_file('/etc/cinder/logging.conf').with(
     :owner   => 'cinder',
     :group   => 'cinder',
     :mode    => '0600',
     :require => 'File[/etc/cinder/cinder.conf]'
    ) }

    it { should contain_cinder_config('DEFAULT/log_config_append').with_value('/etc/cinder/logging.conf') }
  end

end

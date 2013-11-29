require 'spec_helper'
describe 'cinder::logging' do
  let :req_params do
    {}
  end

  let :facts do
    {:osfamily => 'Debian'}
  end

  describe 'with only required params' do
    let :params do
      req_params
    end

    it { should contain_class('cinder::params') }

    it 'should not contain default config' do
      #pending('FIXME : according to logging.pp should be absent for defaults!')
      should_not contain_cinder_config('DEFAULT/logging_context_format_string')
      should_not contain_cinder_config('DEFAULT/logging_default_format_string')
      should_not contain_cinder_config('DEFAULT/log_config_append')
      should_not contain_cinder_config('DEFAULT/log_config')
    end
  end

  describe 'with syslog disabled' do
    let :params do
      req_params.merge({
        :log_dir => '/var/log/cinder',
        :use_syslog => false,
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
    it { should_not contain_cinder_config('DEFAULT/use_stderr') }
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

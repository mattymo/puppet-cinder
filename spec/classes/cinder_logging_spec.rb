require 'spec_helper'

describe 'cinder::logging' do

  let :req_params do
    {:use_syslog => 'false'}
  end

  let :facts do
    {:osfamily => 'Debian'}
  end
  describe 'with syslog disabled' do
    let :params do
      req_params
    end

    it { should contain_cinder_config('DEFAULT/use_syslog').with_value(false) }
  end

  describe 'with syslog enabled' do
    let :params do
      req_params.merge({
        :use_syslog   => 'true',
      })
    end

    it { should contain_cinder_config('DEFAULT/use_syslog').with_value(true) }
    it { should contain_cinder_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
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

end

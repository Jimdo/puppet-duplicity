require 'spec_helper'

describe 'duplicity', :type => :define do

  fqdn = 'somehost.domaindomain.org'

  let(:facts) {
    {
      :fqdn => fqdn
    }
  }

  let(:title) { 'some_backup_name' }

  let(:spoolfile) { "/var/spool/duplicity/#{title}.sh" }

  let(:params) {
    {
      :bucket       => 'somebucket',
      :directory    => '/etc/',
      :dest_id      => 'some_id',
      :dest_key     => 'some_key',
    }
  }

  it "adds a cronjob at midnight by default" do

    should contain_cron(title) \
      .with_command(spoolfile) \
      .with_minute(0) \
      .with_hour(0)
  end

  it 'should create the spoolfile before adding the cron using it' do
    should contain_file(spoolfile).with_before("Cron[#{title}]")
  end

  it 'should run the cron as root because backups usually need full access' do
    should contain_cron(title) \
      .with_user('root')
  end

  context "with defined backup time" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id      => 'some_id',
        :dest_key     => 'some_key',
        :hour         => 5,
        :minute       => 23
      }
    }

    it "should be able to handle a specified backup time" do
       should contain_cron(title) \
         .with_minute(23) \
         .with_hour(5)
    end
  end

  context 'with duplicity global parameters passed on' do
    let(:params) {
      {
        :directory    => '/etc/',
      }
    }

    let (:pre_condition) {
      "class { 'duplicity::params' :
        bucket => 'another_bucket',
        dest_id => 'some_id',
        dest_key => 'some_key'
      }"
    }

    it "should be able to use the globally configured cloud key pair" do
      should contain_cron(title) \
        .with_command(spoolfile)

      should contain_file(spoolfile) \
        .with_content(/^export AWS_ACCESS_KEY_ID='some_id'$/)\
        .with_content(/^export AWS_SECRET_ACCESS_KEY='some_key'$/)\
        .with_content(/another_bucket/)

    end
  end

  context 'with ensure => absent' do

    let(:params) {
      {
        :ensure       => 'absent'
      }
    }

    it 'should remove the cron and the duplicity job' do
      should contain_cron(title) \
        .with_ensure('absent')
      should contain_duplicity__job(title) \
        .with_ensure('absent')
    end

  end

  # TODO: test parameter passing for all duplicity::job call
  # permutations
  context "cloud files environment" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :cloud    => 'cf'
      }
    }

    it "should pass the correct cloud backend" do
      should contain_duplicity__job(title) \
        .with_cloud('cf')
    end
  end

end

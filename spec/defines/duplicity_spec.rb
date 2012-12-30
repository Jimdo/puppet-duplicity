require 'spec_helper'

describe 'duplicity', :type => :define do

  fqdn = 'somehost.domaindomain.org'

  let(:facts) {
    {
      :fqdn => fqdn
    }
  }

  let(:title) { 'some_backup_name' }

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

    it "adds a cronjob at midnight be default" do
      should contain_cron('some_backup_name') \
        .with_command("duplicity --full-if-older-than 30D --s3-use-new-style --no-encryption --include '/etc/' --exclude '**' / 'cf\+http://somebucket'") \
        .with_user('root') \
        .with_minute(0) \
        .with_hour(0) \
        .with_environment([ 'CLOUDFILES_USERNAME=\'some_id\'', 'CLOUDFILES_APIKEY=\'some_key\'' ])
    end
  end

  context "no encryption" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key'
      }
    }

    it "adds a cronjob at midnight be default" do
      should contain_cron('some_backup_name') \
        .with_command("duplicity --full-if-older-than 30D --s3-use-new-style --no-encryption --include '/etc/' --exclude '**' / 's3\+http://somebucket/#{fqdn}/some_backup_name/'") \
        .with_user('root') \
        .with_minute(0) \
        .with_hour(0) \
        .with_environment([ 'AWS_ACCESS_KEY_ID=\'some_id\'', 'AWS_SECRET_ACCESS_KEY=\'some_key\'' ])
    end


    it "should make a full backup every X days" do

    end
  end

  context "with defined force full-backup" do

    let(:params) {
      {
        :bucket             => 'somebucket',
        :directory          => '/etc/',
        :dest_id            => 'some_id',
        :dest_key           => 'some_key',
        :full_if_older_than => '5D',
      }
    }

    it "should be able to handle a specified backup time" do
      should contain_cron('some_backup_name') \
        .with_command(/--full-if-older-than 5D/) \
    end
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
       should contain_cron('some_backup_name') \
         .with_minute(23) \
         .with_hour(5)
    end
  end

  context "with defined remove-older-than" do

    let(:params) {
      {
        :bucket             => 'somebucket',
        :directory          => '/etc/',
        :dest_id            => 'some_id',
        :dest_key           => 'some_key',
        :remove_older_than => '7D',
      }
    }

    it "should be able to handle a specified remove-older-than time" do
      should contain_cron('some_backup_name') \
        .with_command(/remove-older-than 7D/) \
    end
  end

  context 'duplicity with pubkey encryption' do

    some_pubkey_id = '15ABDA79'
    fqdn = 'somehost.domaindomain.org'

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/etc/',
        :dest_id  => 'some_id',
        :dest_key => 'some_key',
        :pubkey_id   => some_pubkey_id
      }
    }

    it "should use pubkey encryption if keyid is provided" do
      should contain_cron('some_backup_name') \
        .with_command(/--encrypt-key #{some_pubkey_id}/)
    end

    it "should download and import the specified pubkey" do
      should contain_exec('duplicity-pgp') \
        .with_command("gpg --keyserver subkeys.pgp.net --recv-keys #{some_pubkey_id}") \
        .with_path("/usr/bin:/usr/sbin:/bin") \
        .with_unless("gpg --list-key #{some_pubkey_id}")
    end
  end

  context 'with default bucket and bucket as param' do
    let(:params) {
      {
        :directory    => '/etc/',
        :bucket       => 'from_param'
      }
    }

    let (:pre_condition) {
      "class { 'duplicity::params' :
        bucket => 'default',
        dest_id => 'some_id',
        dest_key => 'some_key'
      }"
    }

    it "should override default bucket with param" do
      should contain_cron('some_backup_name') \
        .with_command(/from_param/)
    end
  end

  context 'duplicity defaults' do
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

    it "contains package" do
      should contain_package('duplicity')
      should contain_package('gnupg')
    end

    it "should be able to set a global cloud key pair config" do
      should contain_cron('some_backup_name') \
        .with_environment([ 'AWS_ACCESS_KEY_ID=\'some_id\'', 'AWS_SECRET_ACCESS_KEY=\'some_key\'' ]) \
        .with_command(/another_bucket/)

    end

    it "should be able to set a global pubkey id" do
    end
  end

  context "with pre_command" do

    let(:params) {
      {
        :bucket       => 'somebucket',
        :directory    => '/root/mysqldump',
        :dest_id      => 'some_id',
        :dest_key     => 'some_key',
        :pre_command  => 'mysqldump database',
      }
    }

    it "should prepend pre_command to cronjob" do
       should contain_cron('some_backup_name') \
         .with_command(/^mysqldump database && /)
    end
  end
end

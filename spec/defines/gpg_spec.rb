require 'spec_helper'

describe 'duplicity::gpg' do

  context 'GPG public key using title' do
  
    some_pubkey_id = '15ABDA79'

    let(:title) { some_pubkey_id }
    
    it "should download and import the specified pubkey" do
      should contain_exec("duplicity-pgp-param-#{some_pubkey_id}") \
        .with_command("gpg --keyserver subkeys.pgp.net --recv-keys #{some_pubkey_id}") \
        .with_path("/usr/bin:/usr/sbin:/bin") \
        .with_unless("gpg --list-key #{some_pubkey_id}")
    end
  end
  
  context 'GPG public key using parameter' do
    
    name = 'Something else'
    some_pubkey_id = '15ABDB79'
  
    let(:params) {
      {
        :pubkey_id    => some_pubkey_id,
      }
    }
    let(:title) { name }
    
    it "should download and import the specified pubkey" do
      should contain_exec("duplicity-pgp-param-#{name}") \
        .with_command("gpg --keyserver subkeys.pgp.net --recv-keys #{some_pubkey_id}") \
        .with_path("/usr/bin:/usr/sbin:/bin") \
        .with_unless("gpg --list-key #{some_pubkey_id}")
    end
  end
  
end
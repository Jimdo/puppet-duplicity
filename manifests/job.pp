define duplicity::job(
  $ensure = 'present',
  $directory = $name,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $pubkey_id = undef,
  $hour = undef,
  $minute = undef,
  $full_if_older_than = undef,
  $remove_older_than = undef,
  $pre_command = undef,
  $default_exit_code = undef,
  $spoolfile,
) {

  include duplicity::params
  include duplicity::packages

  $_bucket = $bucket ? {
    undef => $duplicity::params::bucket,
    default => $bucket
  }

  $_dest_id = $dest_id ? {
    undef => $duplicity::params::dest_id,
    default => $dest_id
  }

  $_dest_key = $dest_key ? {
    undef => $duplicity::params::dest_key,
    default => $dest_key
  }

  $_folder = $folder ? {
    undef => $duplicity::params::folder,
    default => $folder
  }

  $_cloud = $cloud ? {
    undef => $duplicity::params::cloud,
    default => $cloud
  }

  $_pubkey_id = $pubkey_id ? {
    undef => $duplicity::params::pubkey_id,
    default => $pubkey_id
  }

  $_hour = $hour ? {
    undef => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef => $duplicity::params::minute,
    default => $minute
  }

  $_full_if_older_than = $full_if_older_than ? {
    undef => $duplicity::params::full_if_older_than,
    default => $full_if_older_than
  }

  $_pre_command = $pre_command ? {
    undef => '',
    default => "${pre_command} && "
  }

  $_encryption = $_pubkey_id ? {
    undef => '--no-encryption',
    default => "--encrypt-key ${_pubkey_id}"
  }

  $_remove_older_than = $remove_older_than ? {
    undef   => $duplicity::params::remove_older_than,
    default => $remove_older_than,
  }

  if !($_cloud in [ 's3', 'cf' ]) {
    fail('$cloud required and at this time supports s3 for amazon s3 and cf for Rackspace cloud files')
  }

  case $ensure {
    'present' : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }

      if !$_bucket {
        fail('You need to define a container/bucket name!')
      }

      if (!$_dest_id or !$_dest_key) {
        fail('You need to set all of your key variables: dest_id, dest_key')
      }

    }

    'absent' : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }

  $_cfhash = { 'CLOUDFILES_USERNAME' => $_dest_id, 'CLOUDFILES_APIKEY'     => $_dest_key,}
  $_awshash = { 'AWS_ACCESS_KEY_ID'  => $_dest_id, 'AWS_SECRET_ACCESS_KEY' => $_dest_key,}

  $_environment = $_cloud ? {
    'cf' => $_cfhash,
    's3' => $_awshash,
  }

  $_target_url = $_cloud ? {
    'cf' => "'cf+http://${_bucket}'",
    's3' => "'s3+http://${_bucket}/${_folder}/${name}/'"
  }

  $_remove_older_than_command = $_remove_older_than ? {
    undef => '',
    default => " && duplicity remove-older-than ${_remove_older_than} --s3-use-new-style ${_encryption} --force ${_target_url}"
  }

  file { $spoolfile:
    ensure  => $ensure,
    content => template('duplicity/file-backup.sh.erb'),
    owner   => 'root',
    mode    => '0700',
  }

  if ($_pubkey_id and !defined(Duplicity::Gpg[$_pubkey_id])){
    @duplicity::gpg{ $_pubkey_id: }
  }
}

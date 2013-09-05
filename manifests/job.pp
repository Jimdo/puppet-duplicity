define duplicity::job(
  $ensure = 'present',
  $spoolfile = "${duplicity::params::job_spool}/${name}",
  $directory = undef,
  $bucket = $duplicity::params::bucket,
  $dest_id = $duplicity::params::dest_id,
  $dest_key = $duplicity::params::dest_key,
  $folder = $duplicity::params::folder,
  $cloud = $duplicity::params::cloud,
  $pubkey_id = $duplicity::params::pubkey_id,
  $hour = $duplicity::params::hour,
  $minute = $duplicity::params::minute,
  $full_if_older_than = $duplicity::params::full_if_older_than,
  $remove_older_than = $duplicity::params::remove_older_than,
  $pre_command = undef,
  $default_exit_code = undef
) {

  include duplicity::params
  include duplicity::packages

  $_pre_command = $pre_command ? {
    undef => '',
    default => "$pre_command && "
  }

  $_encryption = $pubkey_id ? {
    undef => '--no-encryption',
    default => "--encrypt-key $pubkey_id"
  }

  if !($cloud in [ 's3', 'cf' ]) {
    fail('$cloud required and at this time supports s3 for amazon s3 and cf for Rackspace cloud files')
  }

  case $ensure {
    'present' : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }

      if !$bucket {
        fail('You need to define a container/bucket name!')
      }

      if (!$dest_id or !$dest_key) {
        fail("You need to set all of your key variables: dest_id, dest_key")
      }

    }

    'absent' : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }

  $_cfhash = { 'CLOUDFILES_USERNAME' => $dest_id, 'CLOUDFILES_APIKEY'     => $dest_key,}
  $_awshash = { 'AWS_ACCESS_KEY_ID'  => $dest_id, 'AWS_SECRET_ACCESS_KEY' => $dest_key,}

  $_environment = $cloud ? {
    'cf' => $_cfhash,
    's3' => $_awshash,
  }

  $_target_url = $cloud ? {
    'cf' => "'cf+http://$_bucket'",
    's3' => "'s3+http://$_bucket/$_folder/$name/'"
  }

  $_remove_older_than_command = $remove_older_than ? {
    undef => '',
    default => " && duplicity remove-older-than $remove_older_than --s3-use-new-style $_encryption --force $_target_url"
  }

  file { $spoolfile:
    ensure  => $ensure,
    content => template("duplicity/file-backup.sh.erb"),
    owner   => 'root',
    mode    => 0700,
  }

  # Only create the definition if it's different from the parameters class
  if $pubkey_id != $duplicity::params::pubkey_id {
    exec { "duplicity-pgp-${pubkey_id}":
      command => "gpg --keyserver subkeys.pgp.net --recv-keys $pubkey_id",
      path    => "/usr/bin:/usr/sbin:/bin",
      unless  => "gpg --list-key $pubkey_id"
    }
  }
}

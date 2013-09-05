define duplicity(
  $ensure = 'present',
  $directory = undef,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $pubkey_id = undef,
  $hour = undef,
  $minute = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $remove_older_than = undef,
) {

  include duplicity::params
  include duplicity::packages

  $escapedname = regsubst("${name}.sh", '[/]', '', 'G')
  $spoolfile = "${duplicity::params::job_spool}/${escapedname}"

  duplicity::job { $name :
    ensure => $ensure,
    spoolfile => $spoolfile,
    directory => $directory,
    bucket => $bucket,
    dest_id => $dest_id,
    dest_key => $dest_key,
    folder => $folder,
    cloud => $cloud,
    pubkey_id => $pubkey_id,
    full_if_older_than => $full_if_older_than,
    pre_command => $pre_command,
    remove_older_than => $remove_older_than,
  }

  $_hour = $hour ? {
    undef => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef => $duplicity::params::minute,
    default => $minute
  }

  cron { $name :
    ensure => $ensure,
    command => $spoolfile,
    user => 'root',
    minute => $_minute,
    hour => $_hour,
  }

  File[$spoolfile]->Cron[$name]
}

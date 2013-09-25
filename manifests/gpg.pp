# Class for retrieving GPG keys.
#   This should probably be removed and
#   the task delegated to a GPG module,
#   for example https://github.com/crayfishx/puppet-gpg
#
define duplicity::gpg(
  $pubkey_id = $name
){

  exec { "duplicity-pgp-param-${name}":
    command => "gpg --keyserver subkeys.pgp.net --recv-keys ${pubkey_id}",
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "gpg --list-key ${pubkey_id}"
  }
}
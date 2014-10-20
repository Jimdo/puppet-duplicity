class duplicity::packages {
  # Install the packages
  ensure_packages(
    ['duplicity', 'python-boto', 'gnupg']
  )
}

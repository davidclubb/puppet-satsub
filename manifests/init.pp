class satsub (
    $satellite_server = 'satellite_host',
    $satellite_org    = 'Default_Organization',
    $satellite_key    = 'satellite_ak',
    $command          = '/usr/bin/subscription-manager register',
    $creates_file     = '/etc/pki/consumer/cert.pem',
) {

  if $::osfamily != 'RedHat' {
    fail("You can't register ${::operatingsystem} with Satellite using this puppet module")
  }

  package { "katello-ca-consumer-${satellite_server}":
    provider => 'rpm',
    ensure   => 'installed',
    source   => "http://${satellite_server}/pub/katello-ca-consumer-latest.noarch.rpm"
  }

  package { 'katello-agent':
    ensure  => 'installed',
    require => Package["katello-ca-consumer-${satellite_server}"]
  }

  exec { 'register_with_satellite':
    command  => "${command} --org=\"${satellite_org}\" --name=\"${::fqdn}\" --activationkey=\"${satellite_key}\"",
    creates  => $creates_file,
    notify   => Exec['startup_goferd'],
    require  => Package["katello-ca-consumer-${satellite_server}"]
  }

  exec { 'startup_goferd':
    command     => "/sbin/chkconfig goferd on",
    require     => Package['katello-agent'],
    refreshonly => true
  }
}

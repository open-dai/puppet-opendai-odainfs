# Class: odainfs
#
# This module manages odainfs
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class odainfs ($package_url = "http://",) {
  package { 'unzip': ensure => present, }
  $folder1 = '/var/geo_data'
  $folder1_user = 'jbossas'
  $folder1_group = 'jbossas'

  $folder2 = '/var/app_data'

  # Create group and user
  group { "$folder1_group":
    ensure => present,
    gid    => 1001
  }

  user { "$folder1_user":
    ensure     => present,
    managehome => true,
    gid        => "$folder1_group",
    uid        => 1001,
    require    => Group["$folder1_group"],
    comment    => 'JBoss Application Server'
  }

  file { $folder1:
    ensure  => directory,
    owner   => "$folder1_user",
    group   => "$folder1_group",
    mode    => 0775,
    require => [Group["$folder1_group"], User["$folder1_user"]]
  }
  include nfs::server

  nfs::server::export { $folder1:
    ensure  => 'mounted',
    tag     => 'nfs_geoserver',
    clients => "${::network_eth0}/24(rw,sync,no_subtree_check)"
  }

  file { $folder2:
    ensure  => directory,
    owner   => "$folder1_user",
    group   => "$folder1_group",
    mode    => 0775,
    require => [Group["$folder1_group"], User["$folder1_user"]]
  }
  include nfs::server

  nfs::server::export { $folder2:
    ensure  => 'mounted',
    tag     => 'nfs_app',
    clients => "${::network_eth0}/24(rw,sync,no_subtree_check)"
  }

  # Install TEIID
  $dist_file = 'data.zip'
  # $file_url = 'http://sourceforge.net/projects/teiid/files/teiid/8.2/Final/'
  $file_url = "http://$package_url/"

  exec { 'download_geo_data':
    command   => "/usr/bin/curl -v --progress-bar -o '/tmp/${dist_file}' '${file_url}${dist_file}'",
    creates   => "/tmp/${dist_file}",
    user      => $folder1_user,
    logoutput => true,
    require   => [Package['curl']],
  }

  # Extract the TEIID distribution
  exec { "extract_geo_data":
    command   => "/usr/bin/unzip '/tmp/${dist_file}' -d ${folder1}",
    creates   => "${folder1}/wms.xml",
    cwd       => $folder1,
    user      => $folder1_user,
    group     => $folder1_group,
    logoutput => true,
  #       unless => "/usr/bin/test -d '$jbossas::deploy_dir'",
      require   => [Package['unzip']]
  }

}

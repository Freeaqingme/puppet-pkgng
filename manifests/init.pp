# This configures the PkgNG Package manager on FreeBSD systems, and adds
# support for managing packages with Puppet.  This will eventually be in
# mainline FreeBSD, but for now, we are leaving the installation up to the
# adminstrator, since there is no going back.
# To install PkgNG, one can simply run the following:
# make -C /usr/ports/ports-mgmg/pkg install clean

class pkgng (
  $pkg_dbdir    = $pkgng::params::pkg_dbdir,
  $pkg_cachedir = $pkgng::params::pkg_cachedir,
  $portsdir     = $pkgng::params::portsdir,
) inherits pkgng::params {

  # At the time of this writing, only FreeBSD 9 and up are supported by pkgng
  if ! $pkgng_supported or versioncmp($pkgng_version, "1.1.4") < 0 {
    fail("PKGng is either not supported on your system or it is too old")
  }

  file { "/usr/local/etc/pkg.conf":
    notify  => Exec['pkg update'],
    content => "PKG_DBDIR: ${pkg_dbdir}\nPKG_CACHEDIR: ${pkg_cachedir}\n"
  }

  # make sure repo config dir is present
  file { ['/usr/local/etc/pkg', '/usr/local/etc/pkg/repos/']:
    ensure => directory,
  }

  file { "/etc/make.conf":
    ensure => present,
  }

  file_line { "WITH_PKGNG":
    path    => '/etc/make.conf',
    line    => "WITH_PKGNG=yes\n",
    require => File['/etc/make.conf'],
  }

  # Triggered on config changes
  exec { "pkg update":
    path        => '/usr/local/sbin',
    refreshonly => true,
    command     => "pkg -q update -f",
  }

  # This exec should really on ever be run once, and only upon converting to
  # pkgng.  If you are building up a new system where the only software that
  # has been installed form ports is the pkgng itself, then the pkg database
  # is already up to date, and this is not required.  As you will see,
  # refreshonly, but nothing notifies this.  I am uncertain at this time how
  # to proceed, other than manually.
  exec { "convert pkg database to pkgng":
    path        => '/usr/local/sbin',
    refreshonly => true,
    command     => "pkg2ng",
  }
}

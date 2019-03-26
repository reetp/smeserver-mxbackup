Summary: MX Backup configuration panel for SME Server
%define name smeserver-mxbackup
Name: %{name}
%define version 0.2
%define release 2
Version: %{version}
Release: %{release}%{?dist}
License: GPL
Group: Networking/Daemons
Source: %{name}-%{version}.tar.gz
#Patch01: %{name}-%{version}-01.patch
#Patch02: %{name}-%{version}-02.patch
Packager: Pascal Schirrmann <schirrms@schirrms.net>
BuildRoot: /var/tmp/%{name}-%{version}-%{release}-buildroot
BuildRequires: e-smith-devtools
BuildArchitectures: noarch
Requires: smeserver-release >= 9
Requires: e-smith-email >= 5.4.0
Requires: e-smith-formmagick >= 2.4.0
Requires: e-smith-base
Requires: e-smith-qmail >= 2.4.0
AutoReqProv: no

%description
Adds a MX Backup Configuration panel to the SME server-manager.

%changelog
* Tue Mar 26 2019 John Crisp <jcrisp@safeandsoundit.co.uk> 0.2-2.sme
- Updated readme
- Comment out debugging in pm file

* Fri Jun 30 2017 John Crisp <jcrisp@safeandsoundit.co.uk> 0.2-1.sme
- Updating for v9
- Dropped the UTF-8
- Modify the vendor_perl directory

* Sun Apr 20 2008 Pascal Schirrmann <schirrms@schirrms.net>
- This is a fork of smeserver-mxbackup, with utf-8 charset.
  As long as the two versions will exist, the sequence number will stay the same.
  I just increment the version number for the tracker.
[0.1.0-03]
* Wed Apr 26 2006 Pascal Schirrmann <schirrms@schirrms.net>
- Change default to host for any new creation
[0.1.0-02]
* Wed Apr 26 2006 Pascal Schirrmann <schirrms@schirrms.net>
- Fast port to SME 7 : a qpsmtpd configuration file need
  to be altered to accept incoming mails for mx-backuped domains
[0.1.0-01]
* Tue May 11 2004 Pascal Schirrmann <schirrms@schirrms.net>
- New : if the MX-Backup server use a 'smart host' it
  still use DNS for the 'MX-Backuped Domains'
[0.1.0-00]
* Thu Apr 22 2004 Pascal Schirrmann <schirrms@schirrms.net>
- Unable to set a domain containing a Zero !!!
[0.0.4-00]
* Mon Mar 08 2004 Pascal Schirrmann <schirrms@schirrms.net>
- This RPM can only work on SME 6.0 and later, adds a
  require in the 'spec' file
[0.0.3-01]
* Sun Mar 07 2004 Pascal Schirrmann <schirrms@schirrms.net>
- Add some nice stuff, ligths and so on...
  Sounds are awaited for a far future release ;-)
[0.0.3-00]
* Sat Mar 06 2004 Pascal Schirrmann <schirrms@schirrms.net>
- My database conception was not very 'SME-aware'
  majors change in the database storage modes.
[0.0.2-00]
* Wed Mar 03 2004 Pascal Schirrmann <schirrms@schirrms.net>
- some cosmetics change on the package name to be nearer
  of contribs.org naming systems
[0.0.1-01]
* Fri Feb 27 2004 Pascal Schirrmann <schirrms@schirrms.net>
- initial release
[0.0.1-00]

%prep
%setup
# %patch01 -p1
# %patch02 -p1

%build
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root   ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f e-smith-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT > %{name}-%{version}-filelist

%clean
cd ..
rm -rf %{name}-%{version}

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)

%pre

%post
# SME 6 comes with a 'left panel cache' to improve the server panel display speed 
# But I haven't found a nice way to update this cache
# So I chose to do this update here.
if [ -x /etc/e-smith/events/actions/navigation-conf ]
then
	echo "Rebuilding Web Server Manager Left Panel Cache ... Can take up to a minute."
	/etc/e-smith/events/actions/navigation-conf 
	echo "Done."
fi
if [ -x /etc/e-smith/events/actions/initialize-default-databases ]
then
	echo "Setting defaults values in SME configuration database, if needed. Don't change any existing configuration."
	/etc/e-smith/events/actions/initialize-default-databases
	echo "Done."
fi
# regenerate the rcpthosts file, in case of an upgrade
# If this is a new install, this will change nothing, because
# status = disabled
echo "Regenerating the config file..."
/sbin/e-smith/expand-template /var/qmail/control/rcpthosts
/sbin/e-smith/expand-template /var/qmail/control/smtproutes
if [ -e /var/service/qpsmtpd/config/goodrcptto ] 
then
	/sbin/e-smith/expand-template /var/service/qpsmtpd/config/goodrcptto 
fi
# moving 'light' in correct place.
# these lights cannot be installed by the RPM : in case someone
# installs the same lights, there will be a conflict.
/bin/mv -f /etc/e-smith/GreenLight.jpg /etc/e-smith/web/common/
/bin/mv -f /etc/e-smith/RedLight.jpg   /etc/e-smith/web/common/
echo "Installation finished."

%preun

%postun
# rollback the rcpthosts without mxbackup entries
echo "Revert the system as a non MX Backup system."
/sbin/e-smith/expand-template /var/qmail/control/rcpthosts
/sbin/e-smith/expand-template /var/qmail/control/smtproutes
if [ -e /var/service/qpsmtpd/config/goodrcptto ] 
then
	/sbin/e-smith/expand-template /var/service/qpsmtpd/config/goodrcptto 
fi

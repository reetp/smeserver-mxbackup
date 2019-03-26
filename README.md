# smeserver-mxbackup
Koozali SME server MX backup plugin

Config entries:

name:
domain is 1
host is 0

e.g.

# config show mxbackup
mxbackup=service
    name=somedomain.net,1,host.anotherdomain.com,0,altdomain.co.uk,1
    status=enabled


cat /var/qmail/control/rcpthosts

....

# This is the MX layout
# MX Backup Start

somedomain.net
.somedomain.net
host.anotherdomain.com
altdomain.co.uk
.altdomain.co.uk


Empty unless you have a SMTPSmartHost set:

/var/qmail/control/smtproutes

:smart.host.net
somedomain.net:
.somedomain.net:
host.anotherdomain.com:
altdomain.co.uk:
.altdomain.co.uk:


cat /var/service/qpsmtpd/config/goodrcptto

....

# MX Backup entries start
# This is the list of the mail domains,
# from the MX-Backup configuration of the local system.
@somedomain.net
@mail.impamark.co.uk
@altdomain.co.uk
# MX Backup entries end



We could use /var/qmail/bin/qmail-newmrh

qmail-newmrh - prepare morercpthosts for qmail-smtpd

"qmail-newmrh  reads  the  instructions  in /var/lib/qmail/control/morercpthosts and writes
       them into /var/lib/qmail/control/morercpthosts.cdb in a binary  format  suited  for  quick
       access by qmail-smtpd."

This works - generate a file:
/var/qmail/control/morerctphosts

Execute:
/var/qmail/bin/qmail-newmrh

-rw-r--r-- 1 root root  125 Mar 26 12:46 morercpthosts
-rw-r--r-- 1 root root 2334 Mar 26 12:47 morercpthosts.cdb


Do we set a queue lifeteime?

qmail knows, that he is not the master for the domain, and therefore will try the master until timeout /var/qmail/control/queuelifetime.

The default setting is to keep attempting to send an email for 7 days. The parameter value is seconds.

/var/qmail/bin/qmail-showctl |grep life

queuelifetime: (Default.) Message lifetime in the queue is 604800 seconds.


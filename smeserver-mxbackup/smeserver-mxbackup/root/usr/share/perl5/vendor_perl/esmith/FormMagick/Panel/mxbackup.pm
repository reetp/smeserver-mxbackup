#----------------------------------------------------------------------
# $Id: portforwarding.pm,v 1.31 2003/04/08 15:28:55 msoulier Exp $
# vim: ft=perl ts=4 sw=4 et:
#----------------------------------------------------------------------
# copyright (C) 2004 Pascal Schirrmann
# copyright (C) 2002 Mitel Networks Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#----------------------------------------------------------------------

package esmith::FormMagick::Panel::mxbackup;

use strict;
use esmith::ConfigDB;
use esmith::FormMagick;
use esmith::cgi;
use Exporter;

use constant TRUE => 1;
use constant FALSE => 0;

our @ISA = qw(esmith::FormMagick Exporter);

our @EXPORT = qw(
    show_mx_backup create_new validate_name
     display_create_summary
    );

our $VERSION = sprintf '%d.%03d', q$Revision: 0.10 $ =~ /: (\d+).(\d+)/;
our $mdb = esmith::ConfigDB->open
        or die "Can't open the Config database : $!\n" ;

=head1 NAME

esmith::FormMagick::Panels::mxbackup - useful panel functions

=head1 SYNOPSIS

    use esmith::FormMagick::Panels::mxbackup

    my $panel = esmith::FormMagick::Panel::mxbackup->new();
    $panel->display();

=head1 DESCRIPTION

This module is the backend to the mxbackup panel, responsible for
supplying all functions used by that panel. It is a subclass of
esmith::FormMagick itself, so it inherits the functionality of a FormMagick
object.

=head2 new

This is the class constructor.

=cut

sub new {
    my $class = ref($_[0]) || $_[0];
    my $self = esmith::FormMagick->new();
    bless $self, $class;
    # Uncomment the following line for debugging.
    #$self->debug(TRUE);
    return $self;
}

=head2 show_mx_backup

This method displays the hosts or domains for witch we currently
act as an MX Backup

=cut

sub show_mx_backup {
    my $self = shift ;
    my $q = $self->cgi ;

    my $MX = $mdb->get('mxbackup')
        or ($self->error('ERR_NO_MXBACKUP_RECORD') and return undef) ;
    my $empty = 0 ;
    my %MXValues = split /,/, $MX->prop('name') ;
    my $MXStatus = 0 ; 
    $MXStatus = 1 if ( ( $MX->prop('status') || 'disabled' ) eq 'enabled' ) ;
    $empty = 1 if not %MXValues ;
    
    # this was a good idea to put an enable button...
    # But now, the 'unless' test has to be done 2 time !
    unless ($empty) {
        print $q->start_table({-class => 'sme-border'}), "\n        ";
        if ( $MXStatus ) {
                    my $button = "<a class=\"button-like\"" ;
                    $button .= "href=\"mxbackup?page=5&Next=Front&Current=$MXStatus\">" ;
                    $button .= $self->localise('BUTTON_LABEL_STOP_SERVICE') ;
                    $button .= "</a>" ;
            print $q->Tr(
            esmith::cgi::genSmallCell( $q,
                    "<img src=\"/server-common/GreenLight.jpg\" ALT=\"" . 
                    $self->localise('ENABLED') . "\">" ) ,
            esmith::cgi::genSmallCell( $q,
                    $self->localise('SERVICE_RUNNING') ), "          ",
            esmith::cgi::genSmallCell( $q,
                    $button ),"\n        ",
            ),"\n" ;
        } else { 
                    my $button = "<a class=\"button-like\"" ;
                    $button .= "href=\"mxbackup?page=5&Next=Front&Current=$MXStatus\">" ;
                    $button .= $self->localise('BUTTON_LABEL_START_SERVICE') ;
                    $button .= "</a>" ;
            print $q->Tr(
            esmith::cgi::genSmallCell( $q,
                    "<img src=\"/server-common/RedLight.jpg\" ALT=\"" .
                    $self->localise('DISABLED') . "\">" ) ,
            esmith::cgi::genSmallCell( $q,
                    $self->localise('SERVICE_STOPPED') ), "          ",
            esmith::cgi::genSmallCell( $q,
                    $button ),"\n        ",
            ),"\n" ;
        }
    }
    # the 'create button should ever be here ;-)
    print $q->end_table,"\n";
    print $q->Tr(
            $q->td({-colspan => 2 },
                $q->p("&nbsp;"),
            ),
        ),"\n" ;
    print $q->Tr(
            $q->td({-colspan => 2 },
              $q->p("<a class=\"button-like\"" ,
                "href=\"mxbackup?page=0&page_stack=&Next=Create\">" ,
                $self->localise('BUTTON_LABEL_CREATE') ,
                "</a>"))),"\n" ;

    unless ($empty) {
        print $q->Tr(
            $q->td({-colspan => 2},
                $q->p($self->localise('SHOW_MXBACKUP')))),"\n";

        my $q = $self->{cgi};
        print "<tr><td colspan=\"2\">";
        print $q->start_table({-class => 'sme-border'}), "\n        ";
        print $q->Tr(
            esmith::cgi::genSmallCell(
                $q,
                $self->localise('LABEL_NAME'),
                "header"
            ), "        ",
            esmith::cgi::genSmallCell(
                $q,
                $self->localise('LABEL_HOST_DOMAIN'),
                "header",
            ), "        ",
            esmith::cgi::genSmallCell(
                $q,
                $self->localise('ACTION'),
                "header",
            ), "\n        ",
        );
        foreach my $name ( sort { ( join ( "\.", reverse( split /\./, $a) ) )
                                    cmp
                                  ( join( "\.", reverse( split /\./, $b ) ) ) }
                           keys %MXValues ) { 
            my $dom = $self->localise('HOST') ;
            $dom =  $self->localise('DOMAIN') if ( $MXValues{ $name } ) ;
            print $q->Tr(
                esmith::cgi::genSmallCell($q, $name),
                    "        ",
                esmith::cgi::genSmallCell($q, $dom || '&nbsp'),
                    "        ",
                esmith::cgi::genSmallCell(
                    $q,
                    $q->a({href => $q->url(-absolute => 1)
                    . "?page=3&Next=Next&name=$name&"
                    . "host_domain=$dom"},
                    $self->localise('REMOVE'))
                    ),
                   "\n        ",
            );
        }
        print $q->end_table,"\n";
        print '</td></tr>';

    }
    else {
        print '<br><tr><td colspan="2">' .
            $self->localise('NO_MXBACKUP') .
            '</td></tr>';
    }
    return undef;
 
}


=head2 validate_name

This method try to validate the name of domains 'MX Backuped'

=cut

sub validate_name {
    my $self = shift ;
    my $name = $self->{cgi}->param('name') ;
    if ( ! ( $name =~ /^([a-z0-9\-]+\.){1,4}[a-z]{2,5}$/i ) ) {
    # A valid name is 1 to four word + dot, then a word between 2 and 5 characters
        $self->debug_msg("the name $name don't seems to be a valid host or domain name");
        return $self->localise('ERR_BADNAME');
    }
    else
    { return 'OK'; }
}

=head2 mxbackup_enable_disable

This method change the status of MXBackup

=cut

sub mxbackup_enable_disable {
    my $self = shift ;
    $self->debug_msg("Start of sub 'mxbackup_enable_disable'.") ;
    my $current = $self->{cgi}->param('Current') ;
    $self->debug_msg("'mxbackup_enable_disable' : \$current = $current") ;
    my $MX = $mdb->get('mxbackup') 
        || ($self->error('ERR_NO_MXBACKUP_RECORD') and return undef);
    if ( $current ) {
        $MX->set_prop("status", "disabled") ;
        $self->debug_msg("'mxbackup_enable_disable' : mxbackup disabled.") ;
    } else {
        $MX->set_prop("status", "enabled") ;
        $self->debug_msg("'mxbackup_enable_disable' : mxbackup enabled.") ;
    }
    esmith::templates::processTemplate
            ( {
                TEMPLATE_PATH => "/var/qmail/control/rcpthosts",
                PERMS         => 0644,
                UID           => "root",
                GID           => "root",
            } );
    $self->debug_msg("'mxbackup_enable_disable' : rcpthost file regenerated.") ;

    esmith::templates::processTemplate (
            {
                TEMPLATE_PATH => "/var/qmail/control/smtproutes",
                PERMS         => 0644,
                UID           => "root",
                GID           => "root",
            } );
    $self->debug_msg("'mxbackup_enable_disable' : smtproutes file regenerated.") ;
    # arg ! ugly ! I should do that all by an action... how bad !
    # but it's a 'q&d patch' : the whole must be changed in a sme7 mode.
    if ( -e "/var/service/qpsmtpd/config/goodrcptto" ) { #SME 7 server
        esmith::templates::processTemplate
            ( {
            TEMPLATE_PATH => "/var/service/qpsmtpd/config/goodrcptto",
            } );
        $self->debug_msg("'mxbackup_enable_disable' : goodrcptto file regenerated.") ;
    }
    $self->debug_msg("'mxbackup_enable_disable' : \$self->wherenext(\"Finished\");") ;
    $self->wherenext("Finished");
    $self->debug_msg("'mxbackup_enable_disable' : \$self->success();") ;
    $self->success();
    return undef ;
}

=head2 display_summary_create

This is a wrapper for the display_summary method, to call it in create mode. 

=cut

sub display_summary_create {
    my $self = shift;
    $self->display_summary('create');
}

=head2 display_summary_remove

This is a wrapper for the display_summary method, to call it in remove mode.

=cut

sub display_summary_remove {
    my $self = shift;
    $self->display_summary('remove');
}

=head2 display_summary

This method's purpose is to display a summary of the rule about to be added.

=cut

sub display_summary {
    my $self = shift;
    my $mode = shift;
    my $save = $self->localise('SAVE');
    my $cancel = $self->localise('CANCEL');
    my $output = "";
    my $q = $self->{cgi};
    $self->debug_msg("start of method");

    print "<tr><td colspan=\"2\">";

    my $description = "";
    if ($mode eq 'create') {
        $description = $self->localise('SUMMARY_ADD_DESC');
    }
    elsif ($mode eq 'remove') {
        $description = $self->localise('SUMMARY_REMOVE_DESC');
    }
    else {
        $self->error('ERR_UNSUPPORTED_MODE');
        return undef;
    }

    print $q->p($description);

    print $q->start_table({-class => 'sme-border'});
    foreach my $tablearrayref (
            [$self->localise('LABEL_NAME')
                => $q->param('name')],
            [$self->localise('LABEL_HOST_DOMAIN')
                => $self->localise($q->param('host_domain'))]
        )
    {
        print $q->Tr($q->td({-class => 'sme-border-right'}, $tablearrayref->[0]),
                     esmith::cgi::genSmallCell($q, $tablearrayref->[1]),
                     "\n        "
        );
    }
    print $q->end_table, "\n";
    if ($mode eq 'create') {
        print $q->table({-width => '100%'}, $q->Tr($q->th({-class => 'sme-layout'},
                    $q->submit(-name => 'apply',
                        -value => $self->localise('APPLY')),
                    '&nbsp;',
                    $q->submit(-name => 'cancel',
                        -value => $self->localise('CANCEL')))));
    }
    elsif ($mode eq 'remove') {
        print $q->table({-width => '100%'}, $q->Tr($q->th({-class => 'sme-layout'},
                    $q->submit( -name => 'remove',
                        -value => $self->localise('REMOVE')),
                    '&nbsp;',
                    $q->submit( -name => 'cancel',
                        -value => $self->localise('CANCEL')))));
    }
    else { 
        $self->error('ERR_UNSUPPORTED_MODE');
        return undef;
    }
    $self->debug_msg("returning");

    print "</td></tr>";
    return undef;
}

=head2 remove_rule

This method is a remove wrapper for the modify method.

=cut

sub remove_rule {
    my $self = shift;
    $self->modify('remove');
}

=head2 create_new

This method is a create wrapper for the modify method.

=cut

sub create_new {
    my $self = shift;
    $self->modify('create');
}

=head2 modify

This method's purpose is to add or remove rules from the database, and then
cause the firewall rules to update.

=cut

sub modify {
    no strict 'refs';
    my $self = shift;
    my $mode = shift;
    my $q = $self->{cgi};
    $self->debug_msg("at start of modify method");

    # If the cancel button was pressed, just go back to the start page.
    if ($q->param("cancel")) {
        $self->debug_msg("the cancel button was pressed");
        $self->wherenext("Front");
    }
    else {
        # Save the changes. 
        my $name = $q->param('name');
        my $host_domain = $q->param('host_domain');
        my $tpe = 0 ;
        $tpe = 1 if ($host_domain eq 'DOMAIN' );

        $self->debug_msg("name is $name");
        $self->debug_msg("tpe is $tpe");
        $self->debug_msg("host_domain is $host_domain");

        my $MX = $mdb->get('mxbackup') 
            || ($self->error('ERR_NO_MXBACKUP_RECORD') and return undef);
        $self->debug_msg("fetching name property from mxbackup record");
        my %MXValues = split /,/, $MX->prop("name");
        $self->debug_msg("the db property is " . join ( ",", %MXValues ) );

        if ($mode eq 'create') {
            $self->debug_msg("we are in create mode");
            my $newrule = "$name,$tpe";
            $self->debug_msg("new rule is $newrule");
            $MXValues{ $name } = $tpe ;
            $self->debug_msg("MXValues now contains : " . join ( ",", %MXValues ) );
        }
        elsif ($mode eq 'remove') {
            $self->debug_msg("we are in remove mode");
            if ( exists $MXValues{ $name } ) {
                delete $MXValues{ $name }
            }
        }

        $self->debug_msg("We're now writing : " . join ( ",", %MXValues ) );
        $MX->set_prop("name", ( join ",", %MXValues ) ); 
        # if %MXValues is empty, disable the MX Backup feature, enable otherwise
        if ( ( join ",", %MXValues ) eq "" ) {
            $MX->set_prop("status", "disabled")
        } else {
            $MX->set_prop("status", "enabled")
        } 
        esmith::templates::processTemplate
            ( {
                TEMPLATE_PATH => "/var/qmail/control/rcpthosts",
                PERMS         => 0644,
                UID           => "root",
                GID           => "root",
            } );
        $self->debug_msg("rcpthost file regenerated.") ;

        esmith::templates::processTemplate (
            {
                TEMPLATE_PATH => "/var/qmail/control/smtproutes",
                PERMS         => 0644,
                UID           => "root",
                GID           => "root",
            } );
        $self->debug_msg("smtproutes file regenerated.") ;
        # arg ! ugly ! I should do that all by an action... how bad !
        # but it's a 'q&d patch' : the whole must be changed in a sme7 mode.
        if ( -e "/var/service/qpsmtpd/config/goodrcptto" ) { #SME 7 server
            esmith::templates::processTemplate
                ( {
                TEMPLATE_PATH => "/var/service/qpsmtpd/config/goodrcptto",
                } );
            $self->debug_msg("'mxbackup_enable_disable' : goodrcptto file regenerated.") ;
        }

        $self->wherenext("Finished");
        $self->success();
    }
    $self->debug_msg("at end of modify method");
    return undef;
}

1;

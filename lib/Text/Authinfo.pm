package Text::Authinfo;

use v5.12;
use strict;
use warnings;
use File::Copy qw(move);
use Data::Dumper;
use Text::CSV;
use Carp qw(croak carp);
use vars qw($VERSION @EXPORT);
use Exporter;
use base qw(Exporter);

@EXPORT = qw(readauthinfo writeauthinfo as_string);

our $VERSION = '0.01';
our $authinfofile = $ENV{'HOME'} . '/.authinfo';

sub new {
    my $self = {};
    my $class = shift;

    $self->{FILE} = shift || $authinfofile;
    $self->{AUTHINFO} = {};

    bless $self,$class ;
    return $self;
}


sub readauthinfo {
    my $self = shift;

    my $ai = {};
    my $csv = Text::CSV->new({sep_char=> ' '}) || croak 'new Text::CSV';

    open(my $fh,'<',$self->{FILE}) || croak "open $self->{FILE}:$!";

    LINE:while (my $line = <$fh>) {
        chomp $line;
        $csv->parse($line);
        my %l = $csv->fields();
        if (defined($l{'machine'}) &&
            defined($l{'port'})    &&
            defined($l{'login'})   &&
            defined($l{'password'})) {
            $ai->{$l{'machine'}}->{$l{'port'}}->{$l{'login'}} = $l{'password'};
        } else {
            carp "$line missing some fields? skipping";
            next LINE;
        }
    }

    $self->{AUTHINFO} = $ai;

    close($fh) || croak "close $authinfofile:$!";

    return 1; # caller can now query authinfo data as a perl assoc array
}


sub as_string {
    my $self = shift;

    my $c = '';
    for my $machine (keys %{$self->{AUTHINFO}}) {
        for my $port (keys %{$self->{AUTHINFO}->{$machine}}) {
            for my $login (keys %{$self->{AUTHINFO}->{$machine}->{$port}}) {
                my $pass = $self->{AUTHINFO}->{$machine}->{$port}->{$login};
                $c .= 'machine ' . $machine .
                    ' login ' . $login .
                        ' password ' . $pass .
                            ' port ' . $port . "\n";
            }
        }
    }
    return $c;
}


sub writeauthinfo {
    my $self = shift;

    my $ops = shift || undef;
    if (defined($ops) && (ref($ops) ne 'HASH')) {
        carp "args are passed to writeauthinfo via a hash ref";
    }

    if (-w $self->{FILE}) {
        # there is already a .authinfo file, mv it to .authinfo.bak
        if (defined($ops->{nobackup})) {
            unlink $self->{FILE} || croak "rm old $self->{FILE}:$!"
        } else { # by default, make a backup old old authinfo file
            my $bak = $self->{FILE} . '.bak';
            move($self->{FILE},$bak) || croak "mv $self->{FILE} $bak:$!";
        }
    }

    my $c = $self->as_string();
    if ($c) {
        open(my $fh,'>',$self->{FILE}) || croak "open $self->{FILE}:$!";
        print $fh $c;
        close($fh) || croak "close $self->{FILE}:$!";
        chmod 0600, $self->{FILE} || croak "chmod fail on $self->{FILE}:$!";
    }

    return 1;
}

__END__;

1;

=head1 NAME

Text::Authinfo - read, query and write authinfo files

=head1 VERSION

Version 0.01

=head1 STATUS

This package should be considered new and untested. Please use at your own risk.

=head1 SYNOPSIS

  use Text::Authinfo;

  my $a = Text::Authinfo->new();
  my $read_success = $a->readauthinfo();
  print $a->{FILE};
  if (defined($a->{AUTHINFO}->{'example.com'}->{'9090'}->{'myname'})) {
      my $password =
          $a->{AUTHINFO}->{'example.com'}->{'9090'}->{'myname'};
  }
  print $a->as_string();
  my $write_success = $a->writeauthinfo();

=head1 PACKAGE VARIABLES

$authinfofile - the full path of the authinfo file used by default,
which points to ~/.authinfo.

=head1 OBJECT VARIABLES

FILE - the full filename path for the authinfo file

AUTHINFO - the nested hashrefs denoting the authinfo data. This is of the form:

  $a->{AUTHINFO}->{$machine}->{$port}->{$login} = $password;

=head1 SUBROUTINES/METHODS

=head2 new

  my $a1 = Text::Authinfo->new();
  my $a2 = Text::Authinfo->new('/home/me/.otherauthinfofile');

The constructor has an optional argument that can be used to stipulate an
alternative authinfofile to use.

=head2 readauthinfo

  my $read_success = $a->readauthinfo();

Reads the authinfofile data into C<$a-E<gt>{AUTHINFO}>. Returns 1 for
success, 0 otherwise.

=head2 as_string

  print $a->as_string();

=head2 writeauthinfo

  my $write_success1 = $a1->writeauthinfo();
  my $write_success2 = $a2->writeauthinfo({'nobackup'=>1});

Writes the contents of C<$a-E<gt>{AUTHINFO}> into C<$a-E<gt>{FILE}>, while
creating a backup file with the same path as C<$a-E<gt>{FILE}>, but with
'.bak' appended.

Passing a hashref with C<nobackup> set will prevent this behavior.

Note! this function will overwrite your existing authinfo file. This can
be dangerous! Keep backups.

The file written will have mode 0600 applied.

=head1 AUTHOR

brad clawsie, C<< <bclawsie at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-authinfo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Authinfo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Authinfo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Authinfo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Authinfo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Authinfo>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Authinfo/>

=back

=head1 CONTRIBUTING

See the public git repository at:

L<https://github.com/xylabs/perl-Text-Authinfo>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 brad clawsie.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


package Pod::Weaver::Section::ANSITable::BorderStyles;

# DATE
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::Section';

use List::Util qw(first);
use Moose::Autobox;

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename} || 'file';

    my $pkg_p;
    my $pkg;
    my $short_pkg;
    if ($filename =~ m!^lib/(.+/BorderStyle/.+)$!) {
        $pkg_p = $1;
        $pkg = $1; $pkg =~ s/\.pm\z//; $pkg =~ s!/!::!g;
        $short_pkg = $pkg; $short_pkg =~ s/.+::BorderStyle:://;
    } else {
        $self->log_debug(["skipped file %s (not a BorderStyle module)", $filename]);
        return;
    }

    local @INC = @INC;
    unshift @INC, 'lib';
    require $pkg_p;
    require Text::ANSITable;

    my $text;
    {
        no strict 'refs';
        my $border_styles = \%{"$pkg\::border_styles"};
        $text = "=over\n\n";
        for my $style (sort keys %h) {
            my $spec = $border_styles->{$style};
            $text .= "=item * $short_pkg\::$style ($spec->{summary})\n\n";
            $text .= "$spec->{description}\n\n" if $spec->{description};
        }
        $text .= "=back\n\n";
    }

    $document->children->push(
        Pod::Elemental::Element::Nested->new({
            command  => 'head1',
            content  => 'INCLUDED BORDER STYLES',
            children => [
                map { s/\n/ /g; Pod::Elemental::Element::Pod5::Ordinary->new({ content => $_ })} split /\n\n/, $text
            ],
        }),
    );
}

no Moose;
1;
# ABSTRACT: Add an INCLUDED BORDER STYLES section for ANSITable BorderStyle module

=for Pod::Coverage weave_section

=head1 SYNOPSIS

In your C<weaver.ini>:

 [ANSITable::BorderStyles]


=head1 DESCRIPTION

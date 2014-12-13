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
        $text = "";
        for my $style (sort keys %$border_styles) {
            my $spec = $border_styles->{$style};
            $text .= "=head2 $short_pkg\::$style\n\n";
            $text .= "$spec->{summary} " if $spec->{summary};
            $text .= join(
                "",
                "(utf8: ", ($spec->{utf8} ? "yes":"no"), ", ",
                "box_chars: ", ($spec->{box_chars} ? "yes":"no"),
                ").\n\n",
            );
            $text .= "$spec->{description}\n\n" if $spec->{description};
            next if $spec->{box_chars};
            # show sample table
            local $ENV{COLUMNS} = 80;
            my $t = Text::ANSITable->new(
                use_color => 0,
                use_utf8  => 1,
                use_box_chars => 0,
                columns   => [qw/column1 column2/],
            );
            $t->border_style("$short_pkg\::$style");
            $t->add_row(['row1.1', 'row1.2']);
            $t->add_row(['row2.1', 'row3.2']);
            $t->add_row_separator;
            $t->add_row(['row3.1', 'row3.2']);
            my $t_text = $t->draw;
            $t_text =~ s/^/ /gm;
            $text .= $t_text . "\n\n";
        }
    }

    $document->children->push(
        Pod::Elemental::Element::Nested->new({
            command  => 'head1',
            content  => 'INCLUDED BORDER STYLES',
            children => [
                map { Pod::Elemental::Element::Pod5::Ordinary->new({ content => $_ })} split /\n\n/, $text
            ],
        }),
    );
    $self->log(["Inserted INCLUDED BORDER STYLES POD section to file %s", $filename]);
}

no Moose;
1;
# ABSTRACT: Add an INCLUDED BORDER STYLES section for ANSITable BorderStyle module

=for Pod::Coverage weave_section

=head1 SYNOPSIS

In your C<weaver.ini>:

 [ANSITable::BorderStyles]


=head1 DESCRIPTION

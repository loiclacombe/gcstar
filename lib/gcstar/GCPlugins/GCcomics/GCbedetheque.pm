package GCPlugins::GCcomics::GCbedetheque;

###################################################
#
#  Copyright 2005-2010 Christian Jodar
#
#  This file is part of GCstar.
#
#  GCstar is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  GCstar is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with GCstar; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
#
###################################################

use strict;
use utf8;

use GCPlugins::GCcomics::GCcomicsCommon;

{

    package GCPlugins::GCcomics::GCPluginbedetheque;

    use LWP::Simple qw($ua);

    use base qw(GCPlugins::GCcomics::GCcomicsPluginsBase);
    sub getSearchUrl
    {
        my ( $self, $word ) = @_;
        if ($self->{searchField} eq 'series')
        {
            return "http://www.bedetheque.com/search/albums?RechSerie=$word";
        }
        elsif ($self->{searchField} eq 'writer')
        {
            return "http://www.bedetheque.com/search/albums?RechAuteur=$word";
        }
        else
        {
            return '';
        }

        #return "http://www.bedetheque.com/index.php?R=1&RechTexte=$word";
    }

    sub getSearchFieldsArray
    {
        return ['series', 'writer'];
    }

    sub getItemUrl
    {
        my ( $self, $url ) = @_;
        my @array = split( /#/, $url );
        $self->{site_internal_id} = $array[1];

        # print "getItemUrl $url\n\n";
        return $url if $url =~ /^http:/;
        return "http://www.bedetheque.com/" . $url;
    }

    sub getNumberPasses
    {
        return 1;
    }

    sub getName
    {
        return "Bedetheque";
    }

    sub getAuthor
    {
        return 'Mckmonster';
    }

    sub getLang
    {
        return 'FR';
    }

    sub getSearchCharset
    {
        my $self = shift;

        # Need urls to be double character encoded
        return "utf8";
    }

    sub new
    {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = $class->SUPER::new();
        bless( $self, $class );

        $self->{hasField} = {
            series => 1,
            title  => 1,
            volume => 1,
          };

        $self->{isResultsTable}   = 0;
        $self->{isCover}          = 0;
        $self->{itemIdx}          = 0;
        $self->{last_cover}       = "";
        $self->{site_internal_id} = "";
        $self->{serie}            = "";
        $self->{synopsis}         = "";
        $self->{current_field}    = "";

        return $self;
    }

    sub preProcess
    {
        my ( $self, $html ) = @_;

        $self->{parsingEnded} = 0;
        $html =~ s/\s+/ /g;
        $html =~ s/\r?\n//g;

        if ( $self->{parsingList} )
        {
            if ( $html =~ m/(\d+\salbum\(s\).+)/ ) {

                #keep only albums, no series or objects
                $html = $1;
                $self->{alternative} = 0;
            } elsif ( $html =~ m/(<div id="albums_table">.+)/ ) {
                $html = $1;
                $self->{alternative} = 1;
            }
        }
        else
        {
            # print $html ;
            $html =~ m/(<div class="single-title-wrap serie-wrap">.+)/;
            $html = $1;
            $self->{isResultsTable} = 0;
            $self->{parsingEnded}   = 0;
            $self->{isCover} = 0;
            $self->{isTabs} = 0;
            $self->{isLabel} = 0;
            $self->{itemIdx}++;
            #
            $self->{doneColourist}    = 0 ;
            $self->{doneCost}         = 0 ;
            $self->{doneFormat}       = 0 ;
            $self->{doneIllustrator}  = 0 ;
            $self->{doneISBN}         = 0 ;
            $self->{doneNumberboards} = 0 ;
            $self->{donePublishdate}  = 0 ;
            $self->{donePublishdate}  = 0 ;
            $self->{donePublisher}    = 0 ;
            $self->{doneSerie}        = 0 ;
            $self->{doneSynopsis}     = 0 ;
            $self->{doneTitle}        = 0 ;
            $self->{doneVolume}       = 0 ;
            $self->{doneWriter}       = 0 ;
        }

        return $html;
    }

    sub start
    {
        my ( $self, $tagname, $attr, $attrseq, $origtext ) = @_;

        return if ( $self->{parsingEnded} );

        if ( $self->{parsingList} )
        {
            if ( !defined ($self->{alternative}) || (!$self->{alternative}) )
            {
                if ( ( $tagname eq "a" ) && ( $attr->{href} =~ m/album-/ ) )
                {
                    $self->{isCollection} = 1;
                    $self->{itemIdx}++;

                    my $searchUrl =  substr($attr->{href},0,index($attr->{href},".")).substr($attr->{href},index($attr->{href},"."));
                    $self->{itemsList}[$self->{itemIdx}]->{url} = $searchUrl;
                    $self->{itemsList}[$self->{itemIdx}]->{title} = $attr->{title};

                    #$self->{itemsList}[ $self->{itemIdx} ]->{url} =
                    #  "http://www.bedetheque.com/" . $attr->{href};
                }
                elsif ( ( $tagname eq "ul" ) && ( $attr->{class} eq "search-list" ) ) {
                    $self->{inTable} = 1;
                }
                elsif ( ($self->{inTable}) && ( $tagname eq "li" ) ) {
                    $self->{isVolume} = 1;
                }
                elsif ( ($self->{inTable}) && ( $tagname eq "a" ) && ( $attr->{title} eq "tooltip" ) ) {
                    $self->{itemsList}[$self->{itemIdx}]->{image} = $attr->{rel};
                    $self->{itemsList}[$self->{itemIdx}]->{url} = $attr->{href};
                }
                elsif ( ($self->{isVolume}) && ( $tagname eq "span" ) && ( $attr->{class} eq "titre" ) ) {
                    $self->{isTitle} = 1;
                }
                elsif ( ($self->{isVolume}) && ( $tagname eq "span" ) && ( $attr->{class} eq "serie" ) ) {
                    $self->{isSerie} = 1;
                }
                elsif ( ($self->{isVolume}) && ( $tagname eq "span" ) && ( $attr->{class} eq "num" ) ) {
                    $self->{isNumber} = 1;
                }
            } else {
                if ( ( $tagname eq "ul" ) && ( $attr->{class} eq "search-list" ) ) {
                    $self->{inTable} = 1;
                }
                elsif ( ($self->{inTable}) && ( $tagname eq "li" ) ) {
                    $self->{itemIdx}++;
                    $self->{isVolume} = 1;
                }
                elsif ( ($self->{inTable}) && ( $tagname eq "a" ) && ( $attr->{title} eq "tooltip" ) ) {
                    $self->{itemsList}[$self->{itemIdx}]->{image} = $attr->{rel};
                    $self->{itemsList}[$self->{itemIdx}]->{url} = $attr->{href};
                }
                elsif ( ($self->{isVolume}) && ( $tagname eq "span" ) && ( $attr->{class} eq "titre" ) ) {
                    $self->{isTitle} = 1;
                }
                elsif ( ($self->{isVolume}) && ( $tagname eq "span" ) && ( $attr->{class} eq "serie" ) ) {
                    $self->{isSerie} = 1;
                }
                elsif ( ( $self->{isSynopsis} ) && ( $tagname eq "br" ) && ( $self->{startSynopsis} ) ) {

      # This is a stop! for br ;-) and complementary of the p in the end section
      # should be ( ( $tagname eq "p" ) || ( $tagname eq "br" ) )
                    $self->{isSynopsis} = 0;
                    $self->{startSynopsis} = 0;
                    $self->{parsingEnded} = 1;
                }
            }
        }
        else
        {
            if ( ( $self->{isCover} == 0 ) && ( $tagname eq "a" ) && ( $attr->{href} =~ m/Couvertures\/.*\.[jJ][pP][gG]/ ) ) {
                $self->{curInfo}->{image} = $attr->{href};
                $self->{isCover} = 1;
            }
            elsif ( $tagname eq "label" ) {
                $self->{isLabel} = 1;
            }
            elsif ( ( $tagname eq "ul" ) && ( $attr->{class} eq "tabs-album" ) && ( ! $self->{doneSerie} ) ) {
                $self->{isTabs} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{itemprop} eq "name" )           && ( ! $self->{doneTitle} ) ) {
                $self->{isTitle} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{class} eq "titre-rubrique" )    && ( ! $self->{doneSerie} ) && ( $self->{isTabs} ) ) {
                $self->{isSerie} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{itemprop} eq "author" )         && ( ! $self->{doneWriter} ) ) {
                $self->{isWriter} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{itemprop} eq "illustrator" )    && ( ! $self->{doneIllustrator} ) ) {
                $self->{isIllustrator} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{itemprop} eq "illustrator" )    && ( ! $self->{doneColourist} ) && ( $self->{doneIllustrator} ) ) {
                $self->{isColourist} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{itemprop} eq "publisher" )      && ( ! $self->{donePublisher} ) ) {
                $self->{isPublisher} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{itemprop} eq "isbn" )           && ( ! $self->{doneISBN} ) ) {
                $self->{isISBN} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{itemprop} eq "numberOfPages" )  && ( ! $self->{doneNumberboards} ) ) {
                $self->{isNumberboards} = 1;
            }
            elsif ( ( $tagname eq "span" ) && ( $attr->{itemprop} eq "description" )    && ( ! $self->{doneSynopsis} ) ) {
                $self->{isSynopsis} = 1;
            }
            elsif ( ( $tagname eq "ul" ) && ( $attr->{class} eq "liste-albums" ) ) {
                $self->{doneColourist} = 1; # To avoid getting mess with illustrator
            }
#             elsif ( ( $tagname eq "a" ) && ( $attr->{class} eq "titre eo" ) ) {
#                 if ( $attr->{title} =~ m/.+\s-(\d+)-\s.+/ ) {
#                     $self->{curInfo}->{volume} = $1;
#                 }
#             }
        }
    }

    sub text
    {
        my ( $self, $origtext ) = @_;

        return if ( $origtext eq " " );

        return if ( $self->{parsingEnded} );

        if ( $self->{parsingList} )
        {
            if ( !defined ($self->{alternative}) || (!$self->{alternative}) ) {
                if ( $self->{isSerie} == 1)
                {
                    $self->{itemsList}[ $self->{itemIdx} ]->{series}  = $origtext;
                    $self->{isSerie} = 0;
                }
                elsif ( $self->{isTitle} == 1)
                {
                    $self->{itemsList}[ $self->{itemIdx} ]->{title} = $origtext;
                    $self->{isTitle} = 0;
                }
                elsif ( $self->{isNumber} == 1)
                {
                    $self->{itemsList}[ $self->{itemIdx} ]->{volume} = $origtext;
                    $self->{itemsList}[ $self->{itemIdx} ]->{volume} =~ s/#//;
                    $self->{isNumber} = 0;
                }
                else
                {
                    if ($self->{isCollection} == 1)
                    {

                   #sometimes the field is "-vol-title", sometimes "--vol-title"
                        $origtext =~ s/-+/-/;
                        if ( $origtext =~ m/(.+)\s-(\d+)-\s(.+)/ ) {
                            $self->{itemsList}[ $self->{itemIdx} ]->{series} = $1;
                            $self->{itemsList}[ $self->{itemIdx} ]->{volume} = $2;
                        } elsif ( $origtext =~ /-/ ){
                            my @fields = split( /-/, $origtext );
                            $self->{itemsList}[ $self->{itemIdx} ]->{series} = $fields[0];
                            $self->{itemsList}[ $self->{itemIdx} ]->{volume} = $fields[1];
                        }
                        $self->{isCollection} = 0;
                    }
                }
            } else {
                if ( ( $self->{inTable} ) && ( $self->{isTitle} ) ) {
                    $self->{itemsList}[ $self->{itemIdx} ]->{title} = $origtext;
                } elsif ( ( $self->{inTable} ) && ( $self->{isVolume} ) ) {
                    $self->{itemsList}[ $self->{itemIdx} ]->{volume} = $origtext;
                }
            }
        }
        else
        {
            if ( $self->{isResultsTable} == 1 )
            {
                $origtext=~s/:\s+/:/;
                my %td_fields_map = (
                    "Identifiant :"   => '',
                    "Scénario :"      => 'writer',
                    "Dessin :"        => 'illustrator',
                    "Couleurs :"      => 'colourist',
                    "Dépot légal :" => 'publishdate',
                    "Achevé impr. :" => 'printdate ',
                    "Estimation :"    => 'cost',
                    "Editeur :"       => 'publisher',
                    "Collection : "   => 'collection',
                    "Taille :"        => 'format',
                    "ISBN :"          => 'isbn',
                    "Planches :"      => 'numberboards'
                  );

                if ( ( $self->{openlabel} ) && ( exists $td_fields_map{$origtext} ) ) {
                    $self->{current_field} = $td_fields_map{$origtext};
                }
                elsif ( defined ( $self->{current_field} ) && ( $self->{current_field} !~ /^$/ ) )
                {
                    $origtext=~s/&nbsp;/ /g;
                    $origtext=~s/\s+$//g;
                    $self->{curInfo}->{$self->{current_field}} = $origtext;
                    $self->{current_field} = "";
                }
            }
            elsif ( $self->{isTitle} ) {
                $self->{curInfo}->{title} = $origtext;
                $self->{isTitle}   = 0 ;
                $self->{doneTitle} = 1 ;
            }
            elsif ( $self->{isSerie} ) {
                $self->{curInfo}->{series} = $origtext;
                $self->{curInfo}->{series} =~s/^\s+//;
                $self->{isSerie}   = 0 ;
                $self->{doneSerie} = 1 ;
                $self->{isTabs}    = 0 ;
            }
            elsif ( $self->{isWriter} ) {
                $self->{curInfo}->{writer} = $origtext;
                $self->{isWriter}   = 0 ;
                $self->{doneWriter} = 1 ;
            }
            elsif ( $self->{isIllustrator} ) {
                $self->{curInfo}->{illustrator} = $origtext;
                $self->{isIllustrator}   = 0 ;
                $self->{doneIllustrator} = 1 ;
            }
            elsif ( $self->{isColourist} ) {
                $self->{curInfo}->{colourist} = $origtext;
                $self->{isColourist}   = 0 ;
                $self->{doneColourist} = 1 ;
            }
            elsif ( $self->{isPublisher} ) {
                $self->{curInfo}->{publisher} = $origtext;
                $self->{isPublisher}   = 0 ;
                $self->{donePublisher} = 1 ;
            }
            elsif ( $self->{isISBN} ) {
                $self->{curInfo}->{isbn} = $origtext;
                $self->{isISBN}   = 0 ;
                $self->{doneISBN} = 1 ;
            }
            elsif ( $self->{isNumberboards} ) {
                $self->{curInfo}->{numberboards} = $origtext;
                $self->{isNumberboards}   = 0 ;
                $self->{doneNumberboards} = 1 ;
            }
            elsif ( $self->{isVolume} ) {
                $self->{curInfo}->{volume} = $origtext;
                $self->{isVolume}   = 0 ;
                $self->{doneVolume} = 1 ;
            }
            elsif ( ( $self->{isLabel} ) && ( $origtext =~ m/Dépot légal/ ) && ( ! $self->{donePublishdate} ) ) {
                $self->{isPublishdate} = 1 ;
                $self->{isLabel} = 0 ;
            }
            elsif ( $self->{isPublishdate} ) {
                $self->{curInfo}->{publishdate} = $origtext;
                $self->{isPublishdate}   = 0 ;
                $self->{donePublishdate} = 1 ;
            }
            elsif ( ( $self->{isLabel} ) && ( $origtext =~ m/Estimation/ ) && ( ! $self->{doneCost} ) ) {
                $self->{isCost}  = 1 ;
                $self->{isLabel} = 0 ;
            }
            elsif ( $self->{isCost} ) {
                $self->{curInfo}->{cost} = $origtext;
                $self->{isCost}   = 0 ;
                $self->{doneCost} = 1 ;
            }
            elsif ( ( $self->{isLabel} ) && ( $origtext =~ m/Format/ ) && ( ! $self->{doneFormat} ) ) {
                $self->{isFormat} = 1 ;
                $self->{isLabel} = 0 ;
            }
            elsif ( $self->{isFormat} ) {
                $self->{curInfo}->{format} = $origtext;
                $self->{isFormat}   = 0 ;
                $self->{doneFormat} = 1 ;
            }
            elsif ( $self->{isSynopsis} ) {
                $self->{curInfo}->{synopsis} = $origtext;
                $self->{curInfo}->{synopsis} =~ s/^(\s)*//;
                $self->{curInfo}->{synopsis} =~ s/(\s)*$//;
                $self->{isSynopsis}   = 0 ;
                $self->{doneSynopsis} = 1 ;
            }
        }
    }

    sub end
    {
        my ( $self, $tagname ) = @_;

        return if ( $self->{parsingEnded} );

        if ( $self->{parsingList} )
        {
            if ( !defined ($self->{alternative}) || (!$self->{alternative}) ) {
                if ( ( $tagname eq "i" ) && $self->{isCollection} == 1)
                {

                    #end of collection, next field is title
                    $self->{isTitle}      = 1;
                    $self->{isCollection} = 0;
                }
            } else {
                if ( ( $self->{inTable} ) && ( $tagname eq "span" ) ) {
                    $self->{isTitle} = 0;
                } elsif ( ( $self->{inTable} ) && ( $tagname eq "li" ) ) {
                    $self->{isVolume} = 0;
                }
            }
        }
        else
        {
            if ( ( $tagname eq "ul" ) && $self->{isResultsTable} == 1 )
            {
                $self->{isIssue} = 0;
                $self->{isResultsTable} = 0;
            }
            elsif ( $tagname eq "label" ) {
                $self->{openlabel} = 0;
                $self->{isLabel} = 0;
            }
            elsif ( $tagname eq "span" ) {
                $self->{isColourist}    = 0;
                $self->{isIllustrator}  = 0;
                $self->{isISBN}         = 0;
                $self->{isNumberboards} = 0;
                $self->{isPublisher}    = 0;
                $self->{isSerie}        = 0;
                $self->{isSynopsis}     = 0;
                $self->{isTitle}        = 0;
                $self->{isWriter}       = 0;
            }
            elsif ( ( $self->{isSynopsis} ) && ( ( $tagname eq "p" ) || ( $tagname eq "br" ) ) && ( $self->{startSynopsis} ) ) {
                $self->{isSynopsis} = 0;
                $self->{startSynopsis} = 0;
                $self->{parsingEnded}   = 1;
            }
        }
    }
}

1;

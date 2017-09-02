package GCPlugins::GCgames::GCGameSpot;

###################################################
#
#  Copyright 2005-2014 Christian Jodar
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

use GCPlugins::GCgames::GCgamesCommon;

{
    package GCPlugins::GCgames::GCPluginGameSpot;

    use base 'GCPlugins::GCgames::GCgamesPluginsBase';
    use Text::Wrap;

    sub start
    {
        my ($self, $tagname, $attr, $attrseq, $origtext) = @_;
	
        $self->{inside}->{$tagname}++;
        if ($self->{parsingList})
        {
            if ($tagname eq 'head')
            {
                $self->{isGame} = 0;
            }
            elsif (($tagname eq 'ul') && ($attr->{class} eq 'editorial river search-results'))
            {
                $self->{isGame} = 1;
            }
            elsif (($tagname eq 'a') && ($self->{isGame}))
            {
                $self->{itemIdx}++;
                $self->{itemsList}[$self->{itemIdx}]->{url} = 'http://www.gamespot.com'.$attr->{href};
            }
            elsif (($tagname eq 'time') && ($attr->{class} eq 'media-date') && ($self->{isGame}))
            {
                $self->{itemsList}[$self->{itemIdx}]->{released} = $attr->{datetime};
                $self->{isPlatform} = 0;

                my @array = split(/,/,$self->{itemsList}[$self->{itemIdx}]->{platform});
                my $element;

                my $SaveName = $self->{itemsList}[$self->{itemIdx}]->{name};
                my $SaveDate = $self->{itemsList}[$self->{itemIdx}]->{released};
                my $SaveUrl = $self->{itemsList}[$self->{itemIdx}]->{url};
                $self->{itemIdx}--;

                foreach $element (@array)
                {
					if ($element ne '')
					{
	                    $self->{itemIdx}++;
    	                $self->{itemsList}[$self->{itemIdx}]->{name} = $SaveName;
        	            $self->{itemsList}[$self->{itemIdx}]->{released} = $SaveDate;
                	    $self->{itemsList}[$self->{itemIdx}]->{platform} = $element;
		                $self->{itemsList}[$self->{itemIdx}]->{url} = $SaveUrl . 'tpfplatformtpf' . $self->{itemsList}[$self->{itemIdx}]->{platform}. 'tpfreleasetpf' . $self->{itemsList}[$self->{itemIdx}]->{released};
					}
                }
            }
            elsif (($tagname eq 'h3') && ($attr->{class} eq 'media-title') && ($self->{isGame}))
            {
                $self->{isName} = 1;
            }
            elsif (($tagname eq 'div') && ($attr->{class} eq 'media-byline') && ($self->{isGame}))
            {
                $self->{isPlatform} = 1;
            }
            elsif (($tagname eq 'span') && ($self->{isPlatform} eq 1))
            {
                $self->{isPlatform} = 2;
            }
            elsif (($tagname eq 'ul') && ($attr->{class} eq 'paginate'))
            {
                $self->{isGame} = 0;
            }
        }
        elsif ($self->{parsingTips})
        {
            if (($tagname eq 'h2') && ($attr->{class} eq 'cheats__title'))
            {
                $self->{isSection} = 1;
            }
            elsif (($tagname eq 'th') && ($attr->{scope} eq 'row') && ($attr->{class} eq 'cheats__code') && (($self->{section} eq 'Codes') || ($self->{section} eq 'Unlockables')))
            {
                $self->{isCheat} = 1;
            }
            elsif (($tagname eq 'td') && ($attr->{class} eq 'cheats__effect') && ($self->{section} ne ''))
            {
                $self->{isDesc} = 1;
            }
            elsif (($tagname eq 'li') && ($attr->{class} eq 'cheats-list__item'))
            {
                $self->{section} = '';
            }
            elsif ($tagname eq 'head')
            {
                $self->{urlTips} = '';
            }
        }
        else
        {
            if (($tagname eq 'a') && ($self->{isScreen}))
            {
            	if (! $self->{curInfo}->{screenshot1})
                {
                	$self->{curInfo}->{screenshot1} = $attr->{href};
                }
                elsif (! $self->{curInfo}->{screenshot2})
                {
                	$self->{curInfo}->{screenshot2} = $attr->{href};
                }
                $self->{isScreen} = 0;
            }
            elsif (($tagname eq 'a') && ($attr->{href} =~ /\/cheats\//))
            {
                $self->{urlTips} = $attr->{href};
            }
            elsif (($tagname eq 'li') && ($attr->{class} eq 'pod-images__item'))
            {
                $self->{isScreen} = 1;
            }
            elsif (($tagname eq 'img') && ($self->{isBox}))
            {
                $self->{curInfo}->{boxpic} = $attr->{src};
                $self->{curInfo}->{boxpic} =~ s/_medium/_avatar/ if !$self->{bigPics} ;
                $self->{isBox} = 0;
            }
            elsif (($tagname eq 'dt') && ($attr->{class} eq 'pod-objectStats__title'))
            {
                $self->{isGame} = 1 if ! $self->{curInfo}->{name};
            }
            elsif (($tagname eq 'footer') && ($self->{isGame}))
            {
                $self->{isGame} = 0;
                if ($self->{curInfo}->{exclusive} ne 1)
                {
                	$self->{curInfo}->{exclusive} = 0;
                }
            }
            elsif (($tagname eq 'h3') && ($self->{isGame}))
            {
                $self->{isName} = 1 if ! $self->{curInfo}->{name};
            }
            elsif (($tagname eq 'ul') && ($attr->{class} eq 'system-list') && ($self->{isGame}))
            {
                $self->{curInfo}->{exclusive} = 0;
            }
            elsif (($tagname eq 'li') && ($attr->{class} =~ m/system /i) && ($self->{isGame}))
            {
                $self->{curInfo}->{exclusive} = $self->{curInfo}->{exclusive} + 1;
            	$self->{isPlatform} = 1 if ($attr->{class} =~ m/$self->{curInfo}->{platform}/i);
            }
            elsif (($tagname eq 'div') && ($attr->{class} eq 'media-img imgflare--boxart') && ($self->{isGame}))
            {
                $self->{isBox} = 1;
            }
            elsif (($tagname eq 'li') && ($attr->{class} eq 'pod-objectStats__item') && ($self->{isGame}))
            {
                $self->{isEditor} = 0;
                $self->{isDeveloper} = 0;
                $self->{isGenre} = 0;
            }
            elsif (($tagname eq 'dd') && ($attr->{class} eq 'pod-objectStats__deck'))
            {
                $self->{isDesc} = 1;
            }
            elsif (($tagname eq 'div') && ($attr->{class} eq 'gs-score__cell'))
            {
                $self->{isRating} = 1 if ! $self->{curInfo}->{ratingpress};
            }
        }
    }

    sub end
    {
		my ($self, $tagname) = @_;
		
        $self->{inside}->{$tagname}--;
    }

    sub text
    {
        my ($self, $origtext) = @_;

        if ($self->{parsingList})
        {
            if ($self->{isName} eq 1)
            {
                # Enleve les blancs en debut de chaine
                $origtext =~ s/^\s+//;
                # Enleve les blancs en fin de chaine
                $origtext =~ s/\s+$//;

                $self->{itemsList}[$self->{itemIdx}]->{name} = $origtext;
                $self->{isName} = 0;
            }
            elsif ($self->{isPlatform} eq 2)
            {
                # Enleve les blancs en debut de chaine
                $origtext =~ s/^\s+//;
                # Enleve les blancs en fin de chaine
                $origtext =~ s/\s+$//;

                if ($self->{itemsList}[$self->{itemIdx}]->{platform} eq '')
                {
                	$self->{itemsList}[$self->{itemIdx}]->{platform} = $origtext;
                }
                else
                {
                	$self->{itemsList}[$self->{itemIdx}]->{platform} .= ','.$origtext;
                }

                $self->{isPlatform} = 1;
            }
        }
        elsif ($self->{parsingTips})
        {
            if (($self->{isSection}) && $self->{inside}->{h2})
            {
                $self->{section} = 'Codes' if $origtext =~ /^Cheat Codes/i;
                $self->{section} = 'Codes' if $origtext =~ /cheats/i;
                $self->{section} = 'Unlockables' if $origtext =~ /^Unlockables/i;
                $self->{section} = 'Unlockables' if $origtext =~ /^Achievements/i;
                $self->{section} = 'Unlockables' if $origtext =~ /^Trophies/i;
                $self->{section} = 'Unlockables' if $origtext =~ /^Steam Achievements/i;
                $self->{section} = 'Secrets' if $origtext =~ /^Secrets/i;
                $self->{section} = 'Secrets' if $origtext =~ /^Easter Eggs/i;
                
                $self->{section} = 'Secrets' if $self->{section} eq '';
                $self->{section} = '' if $origtext =~ /Walkthrough/i;
                $self->{section} = '' if $origtext =~ /FAQ/i;
                $self->{isSection} = 0;

            }
            elsif (($self->{section} eq 'Codes') || ($self->{section} eq 'Unlockables'))
            {
                $origtext =~ s/^\s*//;
                $origtext =~ s/\s*$//;
                $Text::Wrap::columns = 80;
                $origtext = Text::Wrap::wrap('', '', $origtext);
                
                if ($self->{isCheat})
                {
                    if ($self->{section} eq 'Codes')
                    {
                        $self->{tmpCheatLine} = [];
                        push @{$self->{tmpCheatLine}}, $origtext;
                    }
                    else
                    {
                        $self->{tmpCheatLine} = [];
                        ${$self->{tmpCheatLine}}[1] = $origtext;
                    }
                    $self->{isCheat} = 0;
                }
                elsif ($self->{isDesc})
                {
                    if ($self->{section} eq 'Codes')
                    {
                        push @{$self->{tmpCheatLine}}, $origtext;
                        push @{$self->{curInfo}->{code}}, $self->{tmpCheatLine};
                        $self->{tmpCheatLine} = [];
                    }
                    else
                    {
                        ${$self->{tmpCheatLine}}[0] = $origtext;
                        push @{$self->{curInfo}->{unlockable}}, $self->{tmpCheatLine};
                        $self->{tmpCheatLine} = [];
                    }
                    $self->{isDesc} = 0;
                }
            }
            
            if ($self->{section} eq 'Secrets')
            {
                $origtext =~ s/^\s*//;
                $origtext =~ s/\s*$//;
                return if !$origtext;
                # Un peu de mise en page
                $self->{curInfo}->{secrets} .= "\n\n" if (($self->{curInfo}->{secrets}) && ($self->{inside}->{h2}));
                $self->{curInfo}->{secrets} .= "\n" if (($self->{curInfo}->{secrets}) && (! $self->{inside}->{td}) && (! $self->{inside}->{h2}) && ($origtext ne 'Effect'));
                $self->{curInfo}->{secrets} .= "\t\t\t" if (($self->{curInfo}->{secrets}) && ($self->{inside}->{td}));
                $self->{curInfo}->{secrets} .= "\t\t\t" if (($self->{curInfo}->{secrets}) && ($origtext eq 'Effect'));

                $self->{curInfo}->{secrets} .= $origtext;
            }
        }
        else
        {
            if ($self->{isName})
            {
                $origtext =~ s/\n//g;
                $self->{curInfo}->{name} = $origtext;
                $self->{curInfo}->{platform} = $self->{url_plateforme};
                $self->{curInfo}->{released} = $self->{url_release};
                $self->{isName} = 0;
            }
            elsif ($self->{isPlatform})
            {
                $self->{curInfo}->{platform} = $origtext;
                $self->{isPlatform} = 0;
            }
            elsif (($origtext eq 'Published By:') && ($self->{isGame}))
            {
                $self->{isEditor} = 1;
            }
            elsif (($origtext eq 'Developed By:')&& ($self->{isGame}))
            {
                $self->{isDeveloper} = 1;
            }
            elsif (($origtext eq 'Genre:')&& ($self->{isGame}))
            {
                $self->{isGenre} = 1;
            }
            elsif ($self->{isRating})
            {
                # Enleve les blancs en debut de chaine
                $origtext =~ s/^\s+//;
                # Enleve les blancs en fin de chaine
                $origtext =~ s/\s+$//;

                $self->{curInfo}->{ratingpress} = $origtext;
                $self->{isRating} = 0;
            }
            elsif ($self->{isDesc})
            {
                # Enleve les blancs en debut de chaine
                $origtext =~ s/^\s+//;
                # Enleve les blancs en fin de chaine
                $origtext =~ s/\s+$//;
                $self->{curInfo}->{description} = $origtext;
                $self->{isDesc} = 0;
            }
            else
            {
                $origtext =~ s/^\s*//;
                $origtext =~ s/\s*$//;
                return if !$origtext;
                if (($self->{isEditor}) && ($origtext ne ','))
                {
                    if ($self->{curInfo}->{editor} ne '')
                    {
                    	$self->{curInfo}->{editor} = $self->{curInfo}->{editor} . ','.$origtext;
                    }
                    else
                    {
                    	$self->{curInfo}->{editor} = $origtext;
                    }
                }
                elsif (($self->{isDeveloper}) && ($origtext ne ','))
                {
                    if ($self->{curInfo}->{developer} ne '')
                    {
                    	$self->{curInfo}->{developer} = $self->{curInfo}->{developer} . ','.$origtext;
                    }
                    else
                    {
                    	$self->{curInfo}->{developer} = $origtext;
                    }
                }
                elsif (($self->{isGenre}) && ($origtext ne ','))
                {
                    if ($self->{curInfo}->{genre} ne '')
                    {
                    	$self->{curInfo}->{genre} = $self->{curInfo}->{genre} . ','.$origtext;
                    }
                    else
                    {
                    	$self->{curInfo}->{genre} = $origtext;
                    }
                }
                elsif ($self->{isPlayers} eq 2)
                {
                    $origtext =~ s/(Players?)?\s*\(.*?$//;
                    $self->{curInfo}->{players} = $origtext;
                    $self->{isPlayers} = 0;
                }
            }
        }
    } 

    sub getTipsUrl
    {
        my $self = shift;
        return 'http://www.gamespot.com' .$self->{urlTips};
    }

    sub new
    {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = $class->SUPER::new();
        bless ($self, $class);

        $self->{hasField} = {
            name => 1,
            platform => 1,
            released => 1,
        };

        $self->{isName} = 0;
        $self->{isGame} = 0;
        $self->{isPlatform} = 0;
        $self->{isCheat} = 0;
        $self->{isDesc} = 0;
        $self->{isTip} = 0;
        $self->{isRating} = 0;
        $self->{section} = '';
        $self->{isSection} = 0;
        $self->{isDeveloper} = 0;
        $self->{isGenre} = 0;
        $self->{isEditor} = 0;
        $self->{isReleased} = 0;
        $self->{isPlayers} = 0;
        $self->{isBox} = 0;
        $self->{isScreen} = 0;
        $self->{urlTips} = "";
        $self->{url_plateforme} = '';
        $self->{url_release} = '';

        return $self;
    }

    sub preProcess
    {
        my ($self, $html) = @_;

        if ($self->{parsingTips})
        {
        		my $found = index($html,"Cheats For " . $self->{curInfo}->{platform});
        		if ( $found >= 0 )
		        {
        		    $html = substr($html, $found + length('Cheats For ' . $self->{curInfo}->{platform}),length($html)- $found -length('Cheats For ' . $self->{curInfo}->{platform}) );
        			$found = index($html,"\"tab-pane \"");
	        		if ( $found >= 0 )
			        {
	        		    $html = substr($html, 0, $found);
			        }
		        }
				$html =~ s|</h2>||;

## It takes too much time
#            $html =~ s|<li class="guideAct"><a href="(.+)">Go to Online Walkthrough|'<tpfdebuttpf>' . $self->RecupSolution($1) . '<tpffintpf>'|ge;
        }
        elsif ($self->{parsingList})
        {
        }
        else
        {
        }

        return $html;
    }
    
    sub RecupSolution
    {
        my ($self, $url) = @_;

        my $html = $self->loadPage($url);

        my $found = index($html,"<h2>");
        if ( $found >= 0 )
        {
            $html = substr($html, $found,length($html)- $found);
        }
        else
        {
            $found = index($html,"<span class=\"author\">");
            if ( $found >= 0 )
            {
                $html = substr($html, $found,length($html)- $found);
            }
        }

        $html = substr($html, 0, index($html, " rel=\"next\">"));

        $html =~ s|<a class="next" href="/gameguides.html"||ge;
        $html =~ s|<a class="next" href="(.+)"|$self->RecupSolution('http://www.gamespot.com'.$1)|ge;

        return $html;
    }

    sub getSearchUrl
    {
		my ($self, $word) = @_;
	
        #return 'http://www.gamespot.com/search.html?qs='.$word.'&sub=g&stype=11&type=11';
        #return 'http://www.gamespot.com/pages/search/solr_search_ajax.php?q='.$word.'&type=game&offset=0&tags_only=false&sort=false';
        #return 'http://www.gamespot.com/search/?qs='.$word.'&filter=summary';
        #return 'http://www.gamespot.com/search.html?qs=' .$word. '&tag=masthead%3Bsearch';
        return 'http://www.gamespot.com/search/?indices[0]=game&page=1&q='.$word;
    }
    
    sub getItemUrl
    {
		my ($self, $url) = @_;

        my $found = index($url,"tpfplatformtpf");
        if ( $found >= 0 )
        {
            $self->{url_plateforme} = substr($url, $found +length('tpfplatformtpf'),length($url)- $found -length('tpfplatformtpf'));
            $url = substr($url, 0,$found);
        	$found = index($self->{url_plateforme},"tpfreleasetpf");
    	    if ( $found >= 0 )
	        {
            	$self->{url_release} = substr($self->{url_plateforme}, $found +length('tpfreleasetpf'),length($self->{url_plateforme})- $found -length('tpfreleasetpf'));
	            $self->{url_plateforme} = substr($self->{url_plateforme}, 0, $found);
	        }
        }

        return 'http://www.gamespot.com' . $url
            if $url !~ /gamespot\.com/;
        return $url if $url;
        return 'http://www.gamespot.com';
    }

    sub getName
    {
        return 'GameSpot';
    }
    
    sub getAuthor
    {
        return 'Tian';
    }
    
    sub getLang
    {
        return 'EN';
    }

    sub getCharset
    {
        my $self = shift;
    
        return "ISO-8859-1";
    }
    sub isPreferred
    {
        return 1;
    }
}

1;

package GCPlugins::GCgames::GCMobyGames;

###################################################
#
#  Copyright 2005-2015 Christian Jodar
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
    package GCPlugins::GCgames::GCPluginMobyGames;

    use base 'GCPlugins::GCgames::GCgamesPluginsBase';
    use HTML::Entities;

    sub extractTips
    {
        my ($self, $html_ini) = @_;
        my $answer = "";
        my $html = $self->loadPage($html_ini, 0, 1);
        $html =~ s|<ul>||gi;
        $html =~ s|</ul>||gi;
        $html =~ s|<b>||gi;
        $html =~ s|</b>||gi;
        $html =~ s|<li>||gi;
        $html =~ s|</li>||gi;
        $html =~ s|</h3>||gi;
        $html =~ s|<hr />||gi;
        $html =~ s|<br>|\n|gi;
        $html =~ s|<p>|\n|gi;
        $html =~ s|</p>||gi;
        $html =~ s|<pre>||gi;
        $html =~ s|</pre>||gi;
        $html =~ s|</td>||gi;
        $html =~ s|</tr>||gi;
        my $found = index($html,"sbR sbL sbB\">");
        if ( $found >= 0 )
        {
           $answer = substr($html, $found + length('sbR sbL sbB">'),length($html)- $found -length('sbR sbL sbB">') );
           $answer = substr($answer, 0, index($answer,"</table>"));

           $answer = decode_entities($answer);
        }

        return $answer;
    }


    sub extractPlayer
    {
        my ($self, $html_ini, $word) = @_;
        my $html = 0;
        my $found = index($html_ini,$word);
        if ( $found >= 0 )
        {
           $html = substr($html_ini, $found + length($word),length($html_ini)- $found -length($word) );
           $html = substr($html,0, index($html,"</a>") );
           $html = reverse($html);
           $html = substr($html,0, index($html,">") );
           $html = reverse($html);
           $html =~ s/&nbsp;/ /g;
           $html =~ s/1 Player/1/;
        }
        return $html;
    }

    sub start
    {
        my ($self, $tagname, $attr, $attrseq, $origtext) = @_;

        $self->{inside}->{$tagname}++;
        if ($self->{parsingList})
        {
            if ( $self->{insideSearchImage}
              && ($tagname eq 'a')
              && ( substr($attr->{href},0,6) eq '/game/' ) )
            {
                # Test if there is a platform name in it
                # (i.e. if we can find a second slash after game/ )
                if ($attr->{href} =~ m|/game/[^/]*/|)
                {
                    if ($self->{currentName})
                    {
                        $self->{itemIdx}++;
                        $self->{itemsList}[$self->{itemIdx}]->{url} = 'http://www.mobygames.com'.$attr->{href}.'';
                        $self->{itemsList}[$self->{itemIdx}]->{name} = $self->{currentName};
                        $self->{isPlatform} = 1;
                    }
                    else
                    {
                        # This is a game we want to add
                        $self->{isGame} = 1;
                        $self->{itemIdx}++;
                        $self->{itemsList}[$self->{itemIdx}]->{url} = 'http://www.mobygames.com'.$attr->{href}.'';
                        $self->{isName} = 1 ;
                    }
                }
                else
                {
                    # We will need the name later
                    $self->{isGameName} = 1;
                }
            }
            elsif ( ($tagname eq 'a') && ( substr($attr->{href},0,7) eq '/search' ) )
            {
                $self->{isGame} = 0;
            }
            elsif ( ($tagname eq 'div') && ($attr->{class} eq 'searchData'))
            {
            	$self->{insideSearchImage} = 1;
            }
            elsif ($tagname eq 'br')
            {
                if ($attr->{clear} eq 'all') 
                {
                    $self->{currentName} = '';
		            $self->{insideSearchImage} = 0;
                }
            }
            elsif ($tagname eq 'em')
            {
                $self->{isDate} = 1;
            }
        }
        elsif ($self->{parsingTips})
        {
            if (($tagname eq 'tr') && ($attr->{class} eq 'mb2'))
            {
                $self->{isSectionTips} = 1;
            }
            elsif ( ($tagname eq 'a') && ($self->{isSectionTips}) )
            {
                $self->{tip_wait} = $self->extractTips('http://www.mobygames.com'.$attr->{href});
            }
            elsif ($tagname eq 'br')
            {
                $self->{isSectionTips} = 0;
            }
            elsif ($tagname eq 'head')
            {
                $self->{isSectionTips} = 0;
            }

        }
        else
        {

            if ( ($tagname eq 'h1') && ($attr->{class} eq 'niceHeaderTitle') )
            {
                    $self->{isName} = 1;
            }
            elsif ($tagname eq 'div')
            {
                    if ($attr->{class} =~ m/scoreBoxBig/i)
                    {
                        $self->{isRating} = 1;
                    }
                    
                    if ($self->{curInfo}->{genre})
                    {
                        $self->{isGenre} = 0;
                    }

                    if ($attr->{class} ne 'listing-detail')
                    {
	                    $self->{isDescription} = 0;
		                $self->{isExclusive} = 0;
                    }

            }
            elsif ($tagname eq 'tpfdescriptiontpf')
            {
	                $self->{isDescription} = 1;
            }
            elsif ( ($tagname eq 'a') && ($attr->{class} eq 'edit') )
            {
                    $self->{isDescription} = 0;
            }
            elsif ( ($tagname eq 'a') && ($self->{isEditor}) )
            {
                    $self->{is} = 'editor';
                    $self->{isEditor} = 0;
            }
            elsif ( ($tagname eq 'a') && ($self->{isDeveloper}) )
            {
                    $self->{is} = 'developer';
                    $self->{isDeveloper} = 0;
            }
            elsif ( ($tagname eq 'a') && ($self->{isExclusive}) )
            {
                if ($self->{isExclusive} eq 1)
                {
	                $self->{isExclusive} = $self->{isExclusive} + 1;
                }
                else
                {
	                $self->{curInfo}->{exclusive} = 0;
	                $self->{isExclusive} = 0;
                }
            }
            elsif ( ($tagname eq 'a') && ($self->{isName}) )
            {
                    $self->{is} = 'name';
	                $self->{curInfo}->{platform} = $self->{url_plateforme};
    	            $self->{curInfo}->{exclusive} = 1;
                    $self->{isName} = 0;
            }
            elsif ( ($tagname eq 'a') && ($self->{isDate}) )
            {
                    $self->{is} = 'released';
                    $self->{isDate} = 0;
            }
            elsif ( ($tagname eq 'a') && ($self->{isGenre}) )
            {
                    $self->{is} = 'genre';
            }
            elsif ($tagname eq 'img')
            {
                if ($attr->{src} =~ m|covers/small|)
                {
                    $attr->{src} =~ s|/small/|/large/|
                        if $self->{bigPics};
                    $self->{curInfo}->{boxpic} = $attr->{src};
                    # From here we try to get back cover
                    my $covers = $self->loadPage($self->{rootUrl}.'/cover-art', 0, 1);
                    $covers =~ m|<img alt=".*?Back Cover".*?src="([^"]*)"|;
		            $self->{curInfo}->{backpic} = $1;
		            $self->{curInfo}->{backpic} =~ s|/small/|/large/|
        		    	if $self->{bigPics};                   
                }
            }
            elsif ($tagname eq 'html')
            {
                my $html = $self->loadPage($self->{curInfo}->{$self->{urlField}}.'/techinfo', 0, 1);
                my $player_offline = $self->extractPlayer($html, "Number&nbsp;of Players: Offline" );
                my $player_online = $self->extractPlayer($html, "Number&nbsp;of Players: Online" );
                my $player_total = $self->extractPlayer($html, "Number&nbsp;of Players Supported" );

                if ($player_total)
                {
                   $self->{curInfo}->{players} = $player_total;
                }
                else
                {
                    if ($player_offline)
                    {
                        $self->{curInfo}->{players} = 'Offline: '.$player_offline;
                    }
                    if ($player_online)
                    {
                        if ( $self->{curInfo}->{players} )
                        {
                            $self->{curInfo}->{players} .= '; Online: '.$player_online;
                        }
                        else
                        {
                            $self->{curInfo}->{players} = 'Online: '.$player_online;
                        }
                    }
                }

                $html = $self->loadPage($self->{curInfo}->{$self->{urlField}}.'/screenshots', 0, 1);
                my $screen = 1;
                while ($html =~ m|src="(/images/shots/[^"]*?)"|g)
                {
                    $self->{curInfo}->{'screenshot'.$screen} = 'http://www.mobygames.com' . $1;
                    $self->{curInfo}->{'screenshot'.$screen} =~ s|/images/shots/s/|/images/shots/l/|
                        if $self->{bigPics};
                    $screen++;
                    last if $screen > 2;
                }
            }
            elsif ( ($tagname eq 'br') && ($self->{isDescription}) )
            {
                $self->{curInfo}->{description} .= "\n";
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
            if ($self->{isName})
            {
                #$self->{itemsList}[$self->{itemIdx}]->{name} = $origtext;
                if ($origtext !~ /^Game:/)
                {
                    if (!$self->{currentName})
                    {
                        $self->{itemsList}[$self->{itemIdx}]->{name} = $origtext;
                    }
                    $self->{isName} = 0;
                }
            }
            elsif ($self->{isPlatform})
            {
                $self->{itemsList}[$self->{itemIdx}]->{platform} = $origtext;
                $self->{itemsList}[$self->{itemIdx}]->{url} = $self->{itemsList}[$self->{itemIdx}]->{url} . 'tpfplatformtpf' . $self->{itemsList}[$self->{itemIdx}]->{platform};
                $self->{isPlatform} = 0;
            }
            elsif ($self->{isGameName})
            {
                $self->{currentName} = $origtext;
                $self->{isGameName} = 0;
            }
            elsif ($self->{isDate})
            {
                # <em> tags enclose both dates and the 'a.k.a.' text, so make sure we
                # ignore the aka ones
                if ($origtext !~ /^a\.k\.a\./)
                {          
                    $self->{itemsList}[$self->{itemIdx}]->{released} = $origtext;
                    if (! $self->{itemsList}[$self->{itemIdx}]->{platform})
                    {
                        $self->{previous} =~ s/[\s\(]*$//g;
                        $self->{itemsList}[$self->{itemIdx}]->{platform} = $self->{previous};
	                    $self->{itemsList}[$self->{itemIdx}]->{url} = $self->{itemsList}[$self->{itemIdx}]->{url} . 'tpfplatformtpf' . $self->{itemsList}[$self->{itemIdx}]->{platform};
                    }
                }
                $self->{isDate} = 0;
            }
            $self->{previous} = $origtext;
        }
        elsif ($self->{parsingTips})
        {
            if ($self->{tip_wait} ne '')
            {
                $self->{isUnlock} = 1 if $origtext =~ /Unlockables/i;
                $self->{isUnlock} = 1 if $origtext =~ /Achievement/i;
                $self->{isCode} = 1 if $origtext =~ /Cheat/i;
            }
            if (($self->{isCode}) || ($self->{isUnlock}))
            {
                $Text::Wrap::columns = 80;
                $self->{tip_wait} = Text::Wrap::wrap('', '', $self->{tip_wait});

                my @array = split(/\n/,$self->{tip_wait});
                my $element;

                foreach $element (@array)
                {
	                if (($element =~ m/:/i) && !($element =~ m/type one of the following code/i))
    	            {
		                $self->{tmpCheatLine} = [];
        		        $self->{tmpCheatLine}[0] = substr($element, 0, index($element,":") );
           				$self->{tmpCheatLine}[1] = substr($element, index($element,":") + length(":"),length($element)- index($element,":") -length(":") );

	                    # Enleve les blancs en debut de chaine
     	                $self->{tmpCheatLine}[0] =~ s/^\s+//;
     	                $self->{tmpCheatLine}[1] =~ s/^\s+//;
          	            # Enleve les blancs en fin de chaine
              	        $self->{tmpCheatLine}[0] =~ s/\s+$//;
              	        $self->{tmpCheatLine}[1] =~ s/\s+$//;

            		    push @{$self->{curInfo}->{code}}, $self->{tmpCheatLine} if ($self->{isCode});
            		    push @{$self->{curInfo}->{unlockable}}, $self->{tmpCheatLine} if ($self->{isUnlock});
                		$self->{tmpCheatLine} = [];
	                }
                }
            	$self->{tip_wait} = '';
            	$self->{isCode} = 0;
            	$self->{isUnlock} = 0;
	        }
            else
            {
	        	if ($self->{curInfo}->{secrets})
    	        {
        	    	$self->{curInfo}->{secrets} .= "\n\n";
				}
                $self->{curInfo}->{secrets} .= $self->{tip_wait};
            	$self->{tip_wait} = '';
			}
        }
        else
        {
            if ($self->{is})
            {
                $origtext =~ s/^\s*//;
                
                if ($self->{is} eq 'platform')
                {
                    $self->{curInfo}->{$self->{is}} = $origtext;
                    $self->{curInfo}->{platform} =~ s/DOS/PC/;
                    $self->{curInfo}->{platform} =~ s/Windows/PC/;
                }
                elsif ($self->{is} eq 'genre')
                {
                    push @{$self->{curInfo}->{genre}}, [ $origtext ];
                }
                else
                {
                    $self->{curInfo}->{$self->{is}} = $origtext;
                }

                $self->{is} = '';
            }
            elsif ($self->{isName} eq 3)
            {
                $self->{curInfo}->{name} = $origtext;
                $self->{curInfo}->{platform} = $self->{url_plateforme};
                $self->{curInfo}->{exclusive} = 1;
                $self->{isName} = 0;
            }
            elsif ($self->{isRating})
            {
                $self->{curInfo}->{ratingpress} = int($origtext/10+0.5);
                $self->{isRating} = 0;
            }
            elsif ($self->{isDescription})
            {
                    $self->{curInfo}->{description} .= $origtext;
            }
            elsif ($origtext eq 'Published by')
            {
                $self->{isEditor} = 1;
            }
            elsif ($origtext eq 'Developed by')
            {
                $self->{isDeveloper} = 1;
            }
            elsif ($origtext eq 'Platforms')
            {
                $self->{isExclusive} = 1;
            }
            elsif ( ($origtext eq 'Also For') || (($origtext eq 'Platforms')))
            {
                $self->{curInfo}->{exclusive} = 0;
            }
            elsif ($origtext eq 'Released')
            {
                $self->{isDate} = 1
            }
            elsif ($origtext eq 'Genre')
            {
                $self->{isGenre} = 1
            }
            elsif ($origtext eq 'Description')
            {
                $self->{isDescription} = 1
            }
        }
    } 

    sub getTipsUrl
    {
        my $self = shift;
        my $url = $self->{curInfo}->{$self->{urlField}}.'/hints';
        $url =~ s/##MobyGames//;
        return $url;
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
            released => 1
        };

        $self->{isName} = 0;
        $self->{isGame} = 0;
        $self->{isGameName} = 0;
        $self->{isPlatform} = 0;
        $self->{isEditor} = 0;
        $self->{isDeveloper} = 0;
        $self->{isDate} = 0;
        $self->{isGenre} = 0;
        $self->{isDescription} = 0;
        $self->{isSectionTips} = 0;
        $self->{isCode} = 0;
        $self->{isUnlock} = 0;
        $self->{is} = '';
        $self->{url_plateforme} = '';
        $self->{isExclusive} = 0;
        $self->{tip_wait} = '';

        return $self;
    }

    sub preProcess
    {
        my ($self, $html) = @_;

        $self->{rootUrl} = $self->{loadedUrl};

        if ($self->{parsingTips})
        {
        }
        elsif ($self->{parsingList})
        {
        }
        else
        {
        	my $found = index($html,"<meta name=\"description\" content=\"");
    	    if ( $found >= 0 )
	        {
        	    my $rech_description = substr($html, $found,length($html)- $found);
	        	$found = index($rech_description,"..");
	    	    if ( $found >= 0 )
		        {
		    	    $rech_description = substr($rech_description, index($rech_description,"for ".$self->{url_plateforme})+length("for ".$self->{url_plateforme}), $found-index($rech_description,"for ".$self->{url_plateforme})-length("for ".$self->{url_plateforme}));
		    	    $rech_description = substr($rech_description, index($rech_description,";")+1, length($rech_description)-index($rech_description,";")-1);
                    # Enleve les blancs en debut de chaine
                    $rech_description =~ s/^\s+//;
	    	    }

            $html =~ s|<i>||g;
            $html =~ s|</i>||g;
            $html =~ s|$rech_description|<tpfdescriptiontpf>$rech_description</tpfdescriptiontpf>|g;

    	    }
        }
        return $html;
    }
    
    sub getSearchUrl
    {
        my ($self, $word) = @_;
        return 'http://www.mobygames.com/search/quick?q='.$word.'&p=-1&search=Go&sFilter=1&sG=on';
    }
    
    sub getItemUrl
    {
        my ($self, $url) = @_;

        my $found = index($url,"tpfplatformtpf");
        if ( $found >= 0 )
        {
            $self->{url_plateforme} = substr($url, $found +length('tpfplatformtpf'),length($url)- $found -length('tpfplatformtpf'));
            $url = substr($url, 0,$found);
        }
		
        return $url if $url;
        return 'http://www.mobygames.com/';
    }

    sub getName
    {
        return 'MobyGames';
    }
    
    sub getAuthor
    {
        return 'TPF';
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
}

1;

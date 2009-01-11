#!/usr/bin/perl

#
# Markdown -- A text-to-HTML conversion tool for web writers
#
# Copyright (c) 2004 John Gruber
# <http://daringfireball.net/projects/markdown/>
#


package Markdown;
require 5.006_000;
use strict;
use warnings;

use Digest::MD5 qw(md5_hex);
use vars qw($VERSION);
$VERSION = '1.0';
# Fri 20 Aug 2004

## Disabled; causes problems under Perl 5.6.1:
# use utf8;
# binmode( STDOUT, ":utf8" );  # c.f.: http://acis.openlib.org/dev/perl-unicode-struggle.html


#
# Global default settings:
#
my $g_empty_element_suffix = " />";     # Change to ">" for HTML output
my $g_tab_width = 4;


#
# Globals:
#

# Regex to match balanced [brackets]. See Friedl's
# "Mastering Regular Expressions", 2nd Ed., pp. 328-331.
my $g_nested_brackets;
$g_nested_brackets = qr{
	(?> 								# Atomic matching
	   [^\[\]]+							# Anything other than brackets
	 | 
	   \[
		 (??{ $g_nested_brackets })		# Recursive set of nested brackets
	   \]
	)*
}x;


# Table of hash values for escaped characters:
my %g_escape_table;
foreach my $char (split //, '\\`*_{}[]()#.!') {
	$g_escape_table{$char} = md5_hex($char);
}


# Global hashes, used by various utility routines
my %g_urls;
my %g_titles;
my %g_html_blocks;



#### Blosxom plug-in interface ##########################################

# Set $g_blosxom_use_meta to 1 to use Blosxom's meta plug-in to determine
# which posts Markdown should process, using a "meta-markup: markdown"
# header. If it's set to 0 (the default), Markdown will process all
# entries.
my $g_blosxom_use_meta = 0;

sub start { 1; }
sub story {
	my($pkg, $path, $filename, $story_ref, $title_ref, $body_ref) = @_;

	if ( (! $g_blosxom_use_meta) or
	     (defined($meta::markup) and ($meta::markup =~ /^\s*markdown\s*$/i))
	     ){
			$$body_ref  = Markdown($$body_ref);
     }
     1;
}


#### Movable Type plug-in interface #####################################
eval {require MT};  # Test to see if we're running in MT.
unless ($@) {
    require MT;
    import  MT;
    require MT::Template::Context;
    import  MT::Template::Context;

	eval {require MT::Plugin};  # Test to see if we're running >= MT 3.0.
	unless ($@) {
		require MT::Plugin;
		import  MT::Plugin;
		my $plugin = new MT::Plugin({
			name => "Markdown",
			description => "A plain-text-to-HTML formatting plugin. (Version: $VERSION)",
			doc_link => 'http://daringfireball.net/projects/markdown/'
		});
		MT->add_plugin( $plugin );
	}

	MT::Template::Context->add_container_tag(MarkdownOptions => sub {
		my $ctx	 = shift;
		my $args = shift;
		my $builder = $ctx->stash('builder');
		my $tokens = $ctx->stash('tokens');

		if (defined ($args->{'output'}) ) {
			$ctx->stash('markdown_output', lc $args->{'output'});
		}

		defined (my $str = $builder->build($ctx, $tokens) )
			or return $ctx->error($builder->errstr);
		$str;		# return value
	});

	MT->add_text_filter('markdown' => {
		label     => 'Markdown',
		docs      => 'http://daringfireball.net/projects/markdown/',
		on_format => sub {
			my $text = shift;
			my $ctx  = shift;
			my $raw  = 0;
		    if (defined $ctx) {
		    	my $output = $ctx->stash('markdown_output'); 
				if (defined $output  &&  $output =~ m/^html/i) {
					$g_empty_element_suffix = ">";
					$ctx->stash('markdown_output', '');
				}
				elsif (defined $output  &&  $output eq 'raw') {
					$raw = 1;
					$ctx->stash('markdown_output', '');
				}
				else {
					$raw = 0;
					$g_empty_element_suffix = " />";
				}
			}
			$text = $raw ? $text : Markdown($text);
			$text;
		},
	});

	# If SmartyPants is loaded, add a combo Markdown/SmartyPants text filter:
	my $smartypants;

	{
		no warnings "once";
		$smartypants = $MT::Template::Context::Global_filters{'smarty_pants'};
	}

	if ($smartypants) {
		MT->add_text_filter('markdown_with_smartypants' => {
			label     => 'Markdown with SmartyPants',
			docs      => 'http://daringfireball.net/projects/markdown/',
			on_format => sub {
				my $text = shift;
				my $ctx  = shift;
				if (defined $ctx) {
					my $output = $ctx->stash('markdown_output'); 
					if (defined $output  &&  $output eq 'html') {
						$g_empty_element_suffix = ">";
					}
					else {
						$g_empty_element_suffix = " />";
					}
				}
				$text = Markdown($text);
				$text = $smartypants->($text, '1');
			},
		});
	}
}
else {
#### BBEdit/command-line text filter interface ##########################
# Needs to be hidden from MT (and Blosxom when running in static mode).

    # We're only using $blosxom::version once; tell Perl not to warn us:
	no warnings 'once';
    unless ( defined($blosxom::version) ) {
		use warnings;

		#### Check for command-line switches: #################
		my %cli_opts;
		use Getopt::Long;
		Getopt::Long::Configure('pass_through');
		GetOptions(\%cli_opts,
			'version',
			'shortversion',
			'html4tags',
		);
		if ($cli_opts{'version'}) {		# Version info
			print "\nThis is Markdown, version $VERSION.\n";
			print "Copyright 2004 John Gruber\n";
			print "http://daringfireball.net/projects/markdown/\n\n";
			exit 0;
		}
		if ($cli_opts{'shortversion'}) {		# Just the version number string.
			print $VERSION;
			exit 0;
		}
		if ($cli_opts{'html4tags'}) {			# Use HTML tag style instead of XHTML
			$g_empty_element_suffix = ">";
		}

        my $filename = $ARGV[0];
        my $filenameOut = $ARGV[0] . ".html";
        
        my $text;
        open( FILE, "< $filename" ) or die "Can't open $filename : $!";
        while( <FILE> ) {
            $text = $text . $_;
        }
        close FILE;
        
        open( FILE, "> $filenameOut" ) or die "Can't open $filenameOut : $!";
        print FILE Markdown($text);
        close FILE
        
        #print "text: $text\n";
        
		#### Process incoming text: ###########################
# 		my $text;
# 		{
# 			local $/;               # Slurp the whole file
# 			$text = <>;
# 		}

#       print Markdown($text);
    }
}



sub Markdown {
#
# Main function. The order in which other subs are called here is
# essential. Link and image substitutions need to happen before
# _EscapeSpecialChars(), so that any *'s or _'s in the <a>
# and <img> tags get encoded.
#
	my $text = shift || return '';

	# Clear the global hashes. If we don't clear these, you get conflicts
	# from other articles when generating a page which contains more than
	# one article (e.g. an index page that shows the N most recent
	# articles):
	%g_urls = ();
	%g_titles = ();
	%g_html_blocks = ();


	# Standardize line endings:
	$text =~ s{\r\n}{\n}g; 	# DOS to Unix
	$text =~ s{\r}{\n}g; 	# Mac to Unix

	# Make sure $text ends with a couple of newlines:
	$text .= "\n\n";

	# Convert all tabs to spaces.
	$text = _Detab($text);

	# Strip any lines consisting only of spaces and tabs.
	# This makes subsequent regexen easier to write, because we can
	# match consecutive blank lines with /\n+/ instead of something
	# contorted like /[ \t]*\n+/ .
	$text =~ s/^[ \t]+$//mg;

	# Turn block-level HTML blocks into hash entries
	$text = _HashHTMLBlocks($text);

	# Strip link definitions, store in hashes.
	$text = _StripLinkDefinitions($text);

	# _EscapeSpecialChars() must be called very early, to get
	# backslash escapes processed.
	$text = _EscapeSpecialChars($text);

	$text = _RunBlockGamut($text);

	$text = _UnescapeSpecialChars($text);

	return $text . "\n";
}


sub _StripLinkDefinitions {
#
# Strips link definitions from text, stores the URLs and titles in
# hash references.
#
	my $text = shift || return '';

	# Link defs are in the form: ^[id]: url "optional title"
	while ($text =~ s{
						^[ \t]*\[(.+)\]:	# id = $1
						  [ \t]*
						  \n?				# maybe *one* newline
						  [ \t]*
						<?(\S+?)>?			# url = $2
						  [ \t]*
						  \n?				# maybe one newline
						  [ \t]*
						(?:
							# Todo: Titles are delimited by "quotes" or (parens).
							["(]
							(.+?)			# title = $3
							[")]
							[ \t]*
						)?	# title is optional
						(?:\n+|\Z)
					}
					{}mx) {
		$g_urls{lc $1} = _EncodeAmpsAndAngles( $2 );	# Link IDs are case-insensitive
		if ($3) {
			$g_titles{lc $1} = $3;
			$g_titles{lc $1} =~ s/"/&quot;/g;
		}
	}

	return $text;
}


sub _HashHTMLBlocks {
	my $text = shift || return '';

	# Hashify HTML blocks:
	# We only want to do this for block-level HTML tags, such as headers,
	# lists, and tables. That's because we still want to wrap <p>s around
	# "paragraphs" that are wrapped in non-block-level tags, such as anchors,
	# phrase emphasis, and spans. The list of tags we're looking for is
	# hard-coded:
	my $block_tags_a = qr/p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math|ins|del/;
	my $block_tags_b = qr/p|div|h[1-6]|blockquote|pre|table|dl|ol|ul|script|noscript|form|fieldset|iframe|math/;

	# First, look for nested blocks, e.g.:
	# 	<div>
	# 		<div>
	# 		tags for inner block must be indented.
	# 		</div>
	# 	</div>
	#
	# The outermost tags must start at the left margin for this to match, and
	# the inner nested divs must be indented.
	# We need to do this before the next, more liberal match, because the next
	# match will start at the first `<div>` and stop at the first `</div>`.
	$text =~ s{
				(						# save in $1
					^					# start of line  (with /m)
					<($block_tags_a)	# start tag = $2
					\b					# word break
					(.*\n)*?			# any number of lines, minimally matching
					</\2>				# the matching end tag
					[ \t]*				# trailing spaces/tabs
					(?=\n+|\Z)	# followed by a newline or end of document
				)
			}{
				my $key = md5_hex($1);
				$g_html_blocks{$key} = $1;
				"\n\n" . $key . "\n\n";
			}egmx;


	#
	# Now match more liberally, simply from `\n<tag>` to `</tag>\n`
	#
	$text =~ s{
				(						# save in $1
					^					# start of line  (with /m)
					<($block_tags_b)	# start tag = $2
					\b					# word break
					(.*\n)*?			# any number of lines, minimally matching
					.*</\2>				# the matching end tag
					[ \t]*				# trailing spaces/tabs
					(?=\n+|\Z)	# followed by a newline or end of document
				)
			}{
				my $key = md5_hex($1);
				$g_html_blocks{$key} = $1;
				"\n\n" . $key . "\n\n";
			}egmx;
	# Special case just for <hr />. It was easier to make a special case than
	# to make the other regex more complicated.	
	$text =~ s{
				(?:
					(?<=\n\n)		# Starting after a blank line
					|				# or
					\A\n?			# the beginning of the doc
				)
				(						# save in $1
					[ \t]*
					<(hr)				# start tag = $2
					\b					# word break
					([^<>])*?			# 
					/?>					# the matching end tag
					(?=\n{2,}|\Z)		# followed by a blank line or end of document
				)
			}{
				my $key = md5_hex($1);
				$g_html_blocks{$key} = $1;
				"\n\n" . $key . "\n\n";
			}egx;

	return $text;
}


sub _RunBlockGamut {
#
# These are all the transformations that form block-level
# tags like paragraphs, headers, and list items.
#
	my $text = shift || return '';

	$text = _DoHeaders($text);

	# Do Horizontal Rules:
	$text =~ s{^( ?\* ?){3,}$}{\n<hr$g_empty_element_suffix\n}gm;
	$text =~ s{^( ?- ?){3,}$}{\n<hr$g_empty_element_suffix\n}gm;
	$text =~ s{^( ?_ ?){3,}$}{\n<hr$g_empty_element_suffix\n}gm;

	$text = _DoLists($text);

	$text = _DoCodeBlocks($text);

	$text = _DoBlockQuotes($text);

	# Make links out of things like `<http://example.com/>`
	$text = _DoAutoLinks($text);

	# We already ran _HashHTMLBlocks() before, in Markdown(), but that
	# was to escape raw HTML in the original Markdown source. This time,
	# we're escaping the markup we've just created, so that we don't wrap
	# <p> tags around block-level tags.
	$text = _HashHTMLBlocks($text);

	$text = _FormParagraphs($text);

	return $text;
}


sub _RunSpanGamut {
#
# These are all the transformations that occur *within* block-level
# tags like paragraphs, headers, and list items.
#
	my $text = shift || return '';

	$text = _DoCodeSpans($text);

	# Fix unencoded ampersands and <'s:
	$text = _EncodeAmpsAndAngles($text);

	# Process anchor and image tags. Images must come first,
	# because ![foo][f] looks like an anchor.
	$text = _DoImages($text);
	$text = _DoAnchors($text);


	$text = _DoItalicsAndBold($text);

	# Do hard breaks:
	$text =~ s/ {2,}\n/ <br$g_empty_element_suffix\n/g;

	return $text;
}


sub _EscapeSpecialChars {
	my $text = shift || return '';
	my $tokens ||= _TokenizeHTML($text);

	$text = '';   # rebuild $text from the tokens
# 	my $in_pre = 0;	 # Keep track of when we're inside <pre> or <code> tags.
# 	my $tags_to_skip = qr!<(/?)(?:pre|code|kbd|script|math)[\s>]!;

	foreach my $cur_token (@$tokens) {
		if ($cur_token->[0] eq "tag") {
			# Within tags, encode * and _ so they don't conflict
			# with their use in Markdown for italics and strong.
			# We're replacing each such character with its
			# corresponding MD5 checksum value; this is likely
			# overkill, but it should prevent us from colliding
			# with the escape values by accident.
			$cur_token->[1] =~  s! \* !$g_escape_table{'*'}!gx;
			$cur_token->[1] =~  s! _  !$g_escape_table{'_'}!gx;
			$text .= $cur_token->[1];
		} else {
			my $t = $cur_token->[1];
			$t = _EncodeBackslashEscapes($t);
			$text .= $t;
		}
	}
	return $text;
}


sub _DoAnchors {
#
# Turn Markdown link shortcuts into XHTML <a> tags.
#
	my $text = shift || return '';

	#
	# First, handle reference-style links: [link text] [id]
	#
	$text =~ s{
		(					# wrap whole match in $1
		  \[
		    ($g_nested_brackets)	# link text = $2
		  \]

		  [ ]?				# one optional space
		  (?:\n[ ]*)?		# one optional newline followed by spaces

		  \[
		    (.*?)		# id = $3
		  \]
		)
	}{
		my $result;
		my $whole_match = $1;
		my $link_text   = $2;
		my $link_id     = lc $3;

		if ($link_id eq "") {
			$link_id = lc $link_text;     # for shortcut links like [this][].
		}

		if (defined $g_urls{$link_id}) {
			my $url = $g_urls{$link_id};
			$url =~ s! \* !$g_escape_table{'*'}!gx;		# We've got to encode these to avoid
			$url =~ s!  _ !$g_escape_table{'_'}!gx;		# conflicting with italics/bold.
			$result = "<a href=\"$url\"";
			if ( defined $g_titles{$link_id} ) {
				my $title = $g_titles{$link_id};
				$title =~ s! \* !$g_escape_table{'*'}!gx;
				$title =~ s!  _ !$g_escape_table{'_'}!gx;
				$result .=  " title=\"$title\"";
			}
			$result .= ">$link_text</a>";
		}
		else {
			$result = $whole_match;
		}
		$result;
	}xsge;

	#
	# Next, inline-style links: [link text](url "optional title")
	#
	$text =~ s{
		(				# wrap whole match in $1
		  \[
		    ($g_nested_brackets)	# link text = $2
		  \]
		  \(			# literal paren
		  	[ \t]*
			<?(.+?)>?	# href = $3
		  	[ \t]*
			(			# $4
			  (['"])	# quote char = $5
			  (.*?)		# Title = $6
			  \5		# matching quote
			)?			# title is optional
		  \)
		)
	}{
		my $result;
		my $whole_match = $1;
		my $link_text   = $2;
		my $url	  		= $3;
		my $title		= $6;

		$url =~ s! \* !$g_escape_table{'*'}!gx;		# We've got to encode these to avoid
		$url =~ s!  _ !$g_escape_table{'_'}!gx;		# conflicting with italics/bold.
		$result = "<a href=\"$url\"";

		if (defined $title) {
			$title =~ s/"/&quot;/g;
			$title =~ s! \* !$g_escape_table{'*'}!gx;
			$title =~ s!  _ !$g_escape_table{'_'}!gx;
			$result .=  " title=\"$title\"";
		}

		$result .= ">$link_text</a>";

		$result;
	}xsge;

	return $text;
}


sub _DoImages {
#
# Turn Markdown image shortcuts into <img> tags.
#
	my $text = shift || return '';

	#
	# First, handle reference-style labeled images: ![alt text][id]
	#
	$text =~ s{
		(				# wrap whole match in $1
		  !\[
		    (.*?)		# alt text = $2
		  \]

		  [ ]?				# one optional space
		  (?:\n[ ]*)?		# one optional newline followed by spaces

		  \[
		    (.*?)		# id = $3
		  \]

		)
	}{
		my $result;
		my $whole_match = $1;
		my $alt_text    = $2;
		my $link_id     = lc $3;

		if ($link_id eq "") {
			$link_id = lc $alt_text;     # for shortcut links like ![this][].
		}

		$alt_text =~ s/"/&quot;/g;
		if (defined $g_urls{$link_id}) {
			my $url = $g_urls{$link_id};
			$url =~ s! \* !$g_escape_table{'*'}!gx;		# We've got to encode these to avoid
			$url =~ s!  _ !$g_escape_table{'_'}!gx;		# conflicting with italics/bold.
			$result = "<img src=\"$url\" alt=\"$alt_text\"";
			if (defined $g_titles{$link_id}) {
				my $title = $g_titles{$link_id};
				$title =~ s! \* !$g_escape_table{'*'}!gx;
				$title =~ s!  _ !$g_escape_table{'_'}!gx;
				$result .=  " title=\"$title\"";
			}
			$result .= $g_empty_element_suffix;
		}
		else {
			# If there's no such link ID, leave intact:
			$result = $whole_match;
		}

		$result;
	}xsge;

	#
	# Next, handle inline images:  ![alt text](url "optional title")
	# Don't forget: encode * and _

	$text =~ s{
		(				# wrap whole match in $1
		  !\[
		    (.*?)		# alt text = $2
		  \]
		  \(			# literal paren
		  	[ \t]*
			<?(\S+?)>?	# src url = $3
		  	[ \t]*
			(			# $4
			  (['"])	# quote char = $5
			  (.*?)		# title = $6
			  \5		# matching quote
			  [ \t]*
			)?			# title is optional
		  \)
		)
	}{
		my $result;
		my $whole_match = $1;
		my $alt_text    = $2;
		my $url	  		= $3;
		my $title		= '';
		if (defined($6)) {
			$title		= $6;
		}

		$alt_text =~ s/"/&quot;/g;
		$title    =~ s/"/&quot;/g;
		$url =~ s! \* !$g_escape_table{'*'}!gx;		# We've got to encode these to avoid
		$url =~ s!  _ !$g_escape_table{'_'}!gx;		# conflicting with italics/bold.
		$result = "<img src=\"$url\" alt=\"$alt_text\"";
		if (defined $title) {
			$title =~ s! \* !$g_escape_table{'*'}!gx;
			$title =~ s!  _ !$g_escape_table{'_'}!gx;
			$result .=  " title=\"$title\"";
		}
		$result .= $g_empty_element_suffix;

		$result;
	}xsge;

	return $text;
}


sub _DoHeaders {
	my $text = shift || return '';

	# Setext-style headers:
	#	  Header 1
	#	  ========
	#  
	#	  Header 2
	#	  --------
	#
	$text =~ s{ (.+)[ \t]*\n=+[ \t]*\n+ }{
		"<h1>"  .  _RunSpanGamut($1)  .  "</h1>\n\n";
	}egx;

	$text =~ s{ (.+)[ \t]*\n-+[ \t]*\n+ }{
		"<h2>"  .  _RunSpanGamut($1)  .  "</h2>\n\n";
	}egx;


	# atx-style headers:
	#	# Header 1
	#	## Header 2
	#	## Header 2 with closing hashes ##
	#	...
	#	###### Header 6
	#
	$text =~ s{
			^(\#{1,6})	# $1 = string of #'s
			[ \t]*
			(.+?)		# $2 = Header text
			[ \t]*
			\#*			# optional closing #'s (not counted)
			\n+
		}{
			my $h_level = length($1);
			"<h$h_level>"  .  _RunSpanGamut($2)  .  "</h$h_level>\n\n";
		}egmx;

	return $text;
}


sub _DoLists {
#
# Form HTML ordered (numbered) and unordered (bulleted) lists.
#
	my $text = shift || return '';
	my $less_than_tab = $g_tab_width - 1;
	
	# Re-usable patterns to match list item bullets and number markers:
	my $marker_ul  = qr/[*+-]/;
	my $marker_ol  = qr/\d+[.]/;
	my $marker_any = qr/(?:$marker_ul|$marker_ol)/;

	$text =~ s{
			(								# $1
			  (								# $2
			    ^[ ]{0,$less_than_tab}
			    (${marker_any})				# $3 - first list item marker
			    [ \t]+
			  )
			  (?s:.+?)
			  (								# $4
			      \z
			    |
				  \n{2,}
				  (?=\S)
				  (?!						# Negative lookahead for another list item marker
				  	[ \t]*
				  	${marker_any}[ \t]+
				  )
			  )
			)
		}{
			my $list = $1;
			my $list_type = ($3 =~ m/[*+-]/) ? "ul" : "ol";
			# Turn double returns into triple returns, so that we can make a
			# paragraph for the last item in a list, if necessary:
			$list =~ s/\n{2,}/\n\n\n/g;
			my $result = _ProcessListItems($list, $marker_any);
			$result = "<$list_type>\n" . $result . "</$list_type>\n\n";
			$result;
		}egmx;

	return $text;
}

sub _ProcessListItems {
	my $list_str = shift || return '';
	my $marker_any = shift;
	
	# trim trailing blank lines:
	$list_str =~ s/\n{2,}\z/\n/;


	$list_str =~ s{
		(\n)?							# leading line = $1
		(^[ \t]*)						# leading whitespace = $2
		($marker_any) [ \t]+			# list marker = $3
		((?s:.+?)						# list item text   = $4
		(\n{1,2}))
		(?= \n* (\z | \2 ($marker_any) [ \t]+))
	}{
		my $item = $4;
		my $leading_line = $1;
		my $leading_space = $2;

		if ($leading_line or ($item =~ m/\n{2,}/)) {
			$item = _RunBlockGamut(_Outdent($item));
			#$item =~ s/\n+/\n/g;
		}
		else {
			# Recursion for sub-lists:
			$item = _DoLists(_Outdent($item));
			chomp $item;
			$item = _RunSpanGamut($item);
		}

		"<li>" . $item . "</li>\n";
	}egmx;

	return $list_str;
}



sub _DoCodeBlocks {
#
#	Process Markdown `<pre><code>` blocks.
#	

	my $text = shift || return '';

	$text =~ s{
			(?:\n\n|\A)
			(	            # $1 = the code block -- one or more lines, starting with a space/tab
			  (?:
			    (?:[ ]{$g_tab_width} | \t)  # Lines must start with a tab or a tab-width of spaces
			    .*\n+
			  )+
			)
			((?=^[ ]{0,$g_tab_width}\S)|\Z)	# Lookahead for non-space at line-start, or end of doc
		}{
			my $codeblock = $1;
			my $result; # return value

			$codeblock = _EncodeCode(_Outdent($codeblock));
			$codeblock = _Detab($codeblock);
			$codeblock =~ s/\A\n+//; # trim leading newlines
			$codeblock =~ s/\s+\z//; # trim trailing whitespace

			$result = "\n\n<pre><code>" . $codeblock . "\n</code></pre>\n\n";

			$result;
		}egmx;

	return $text;
}


sub _DoCodeSpans {
#
# 	*	Backtick quotes are used for <code></code> spans.
# 
# 	*	You can use multiple backticks as the delimiters if you want to
# 		include literal backticks in the code span. So, this input:
#     
#         Just type ``foo `bar` baz`` at the prompt.
#     
#     	Will translate to:
#     
#         <p>Just type <code>foo `bar` baz</code> at the prompt.</p>
#     
#		There's no arbitrary limit to the number of backticks you
#		can use as delimters. If you need three consecutive backticks
#		in your code, use four for delimiters, etc.
#
#	*	You can use spaces to get literal backticks at the edges:
#     
#         ... type `` `bar` `` ...
#     
#     	Turns to:
#     
#         ... type <code>`bar`</code> ...
#

	my $text = shift || return '';

	$text =~ s@
			(`+)		# $1 = Opening run of `
			(.+?)		# $2 = The code block
			(?<!`)
			\1			# Matching closer
			(?!`)
		@
 			my $c = $2;
 			$c =~ s/^[ \t]*//g; # leading whitespace
 			$c =~ s/[ \t]*$//g; # trailing whitespace
 			$c = _EncodeCode($c);
			"<code>$c</code>";
		@egsx;

	return $text;
}


sub _EncodeCode {
#
# Encode/escape certain characters inside Markdown code runs.
# The point is that in code, these characters are literals,
# and lose their special Markdown meanings.
#
    local $_ = shift || return '';

	# Encode all ampersands; HTML entities are not
	# entities within a Markdown code span.
	s/&/&amp;/g;

	# Do the angle bracket song and dance:
	s! <  !&lt;!gx;
	s! >  !&gt;!gx;

	# Now, escape characters that are magic in Markdown:
	s! \* !$g_escape_table{'*'}!gx;
	s! _  !$g_escape_table{'_'}!gx;
	s! {  !$g_escape_table{'{'}!gx;
	s! }  !$g_escape_table{'}'}!gx;
	s! \[ !$g_escape_table{'['}!gx;
	s! \] !$g_escape_table{']'}!gx;
	s! \\ !$g_escape_table{'\\'}!gx;

	return $_;
}


sub _DoItalicsAndBold {
	my $text = shift || return '';

	# <strong> must go first:
	$text =~ s{ (\*\*|__) (?=\S) (.+?) (?<=\S) \1 }{<strong>$2</strong>}gsx;
	# Then <em>:
	$text =~ s{ (\*|_) (?=\S) (.+?) (?<=\S) \1 }{<em>$2</em>}gsx;

	return $text;
}


sub _DoBlockQuotes {
	my $text = shift || return '';

	$text =~ s{
		  (								# Wrap whole match in $1
			(
			  ^[ \t]*>[ \t]?			# '>' at the start of a line
			    .+\n					# rest of the first line
			  (.+\n)*					# subsequent consecutive lines
			  \n*						# blanks
			)+
		  )
		}{
			my $bq = $1;
			$bq =~ s/^[ \t]*>[ \t]?//gm;	# trim one level of quoting
			$bq =~ s/^[ \t]+$//mg;			# trim whitespace-only lines
			$bq = _RunBlockGamut($bq);		# recurse
			
			$bq =~ s/^/  /g;
			# These leading spaces screw with <pre> content, so we need to fix that:
			$bq =~ s{
					(\s*<pre>.+?</pre>)
				}{
					my $pre = $1;
					$pre =~ s/^  //mg;
					$pre;
				}egsx;

			"<blockquote>\n$bq\n</blockquote>\n\n";
		}egmx;


	return $text;
}


sub _FormParagraphs {
#
#	Params:
#		$text - string to process with html <p> tags
#
	my $text = shift || return '';

	# Strip leading and trailing lines:
	$text =~ s/\A\n+//;
	$text =~ s/\n+\z//;

	my @grafs = split(/\n{2,}/, $text);
	my $count = scalar @grafs;

	#
	# Wrap <p> tags.
	#
	foreach (@grafs) {
		unless (defined( $g_html_blocks{$_} )) {
			$_ = _RunSpanGamut($_);
			s/^([ \t]*)/<p>/;
			$_ .= "</p>";
		}
	}

	#
	# Unhashify HTML blocks
	#
	foreach (@grafs) {
		if (defined( $g_html_blocks{$_} )) {
			$_ = $g_html_blocks{$_};
		}
	}

	return join "\n\n", @grafs;
}


sub _EncodeAmpsAndAngles {
# Smart processing for ampersands and angle brackets that need to be encoded.

	my $text = shift || return '';

	# Ampersand-encoding based entirely on Nat Irons's Amputator MT plugin:
	#   http://bumppo.net/projects/amputator/
 	$text =~ s/&(?!#?[xX]?(?:[0-9a-fA-F]+|\w+);)/&amp;/g;

	# Encode naked <'s
 	$text =~ s{<(?![a-z/?\$!])}{&lt;}gi;

	return $text;
}


sub _EncodeBackslashEscapes {
#
#   Parameter:  String.
#   Returns:    The string, with after processing the following backslash
#               escape sequences.
#
    local $_ = shift || return '';

    s! \\\\  !$g_escape_table{'\\'}!gx;		# Must process escaped backslashes first.
    s! \\`   !$g_escape_table{'`'}!gx;
    s! \\\*  !$g_escape_table{'*'}!gx;
    s! \\_   !$g_escape_table{'_'}!gx;
    s! \\\{  !$g_escape_table{'{'}!gx;
    s! \\\}  !$g_escape_table{'}'}!gx;
    s! \\\[  !$g_escape_table{'['}!gx;
    s! \\\]  !$g_escape_table{']'}!gx;
    s! \\\(  !$g_escape_table{'('}!gx;
    s! \\\)  !$g_escape_table{')'}!gx;
    s! \\\#  !$g_escape_table{'#'}!gx;
    s! \\\.  !$g_escape_table{'.'}!gx;
    s{ \\!  }{$g_escape_table{'!'}}gx;

    return $_;
}


sub _DoAutoLinks {
	my $text = shift || return '';

	$text =~ s{<((https?|ftp):[^'">\s]+)>}{<a href="$1">$1</a>}gi;

	# Email addresses: <address@domain.foo>
	$text =~ s{
		<
		(
			[-.\w]+
			\@
			[-a-z0-9]+(\.[-a-z0-9]+)*\.[a-z]+
		)
		>
	}{
		_EncodeEmailAddress( _UnescapeSpecialChars($1) );
	}egix;

	return $text;
}


sub _EncodeEmailAddress {
#
#	Input: an email address, e.g. "foo@example.com"
#
#	Output: the email address as a mailto link, with each character
#		of the address encoded as either a decimal or hex entity, in
#		the hopes of foiling most address harvesting spam bots. E.g.:
#
#	  <a href="&#x6D;&#97;&#105;&#108;&#x74;&#111;:&#102;&#111;&#111;&#64;&#101;
#       x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;">&#102;&#111;&#111;
#       &#64;&#101;x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;</a>
#
#	Based on a filter by Matthew Wickline, posted to the BBEdit-Talk
#	mailing list: <http://tinyurl.com/yu7ue>
#

	my $addr = shift || return '';

	srand;
	my @encode = (
		sub { '&#' .                 ord(shift)   . ';' },
		sub { '&#x' . sprintf( "%X", ord(shift) ) . ';' },
		sub {                            shift          },
	);

	$addr = "mailto:" . $addr;

	$addr =~ s{(.)}{
		my $char = $1;
		if ( $char eq '@' ) {
			# this *must* be encoded. I insist.
			$char = $encode[int rand 1]->($char);
		} elsif ( $char ne ':' ) {
			# leave ':' alone (to spot mailto: later)
			my $r = rand;
			# roughly 10% raw, 45% hex, 45% dec
			$char = (
				$r > .9   ?  $encode[2]->($char)  :
				$r < .45  ?  $encode[1]->($char)  :
							 $encode[0]->($char)
			);
		}
		$char;
	}gex;

	$addr = qq{<a href="$addr">$addr</a>};
	$addr =~ s{">.+?:}{">}; # strip the mailto: from the visible part

	return $addr;
}


sub _UnescapeSpecialChars {
#
# Swap back in all the special characters we've hidden.
#
	my $text = shift || return '';

	while( my($char, $hash) = each(%g_escape_table) ) {
		$text =~ s/$hash/$char/g;
	}
    return $text;
}


sub _TokenizeHTML {
#
#   Parameter:  String containing HTML markup.
#   Returns:    Reference to an array of the tokens comprising the input
#               string. Each token is either a tag (possibly with nested,
#               tags contained therein, such as <a href="<MTFoo>">, or a
#               run of text between tags. Each element of the array is a
#               two-element array; the first is either 'tag' or 'text';
#               the second is the actual value.
#
#
#   Derived from the _tokenize() subroutine from Brad Choate's MTRegex plugin.
#       <http://www.bradchoate.com/past/mtregex.php>
#

    my $str = shift || return '';
    my $pos = 0;
    my $len = length $str;
    my @tokens;

    my $depth = 6;
    my $nested_tags = join('|', ('(?:<[a-z/!$](?:[^<>]') x $depth) . (')*>)' x  $depth);
    my $match = qr/(?s: <! ( -- .*? -- \s* )+ > ) |  # comment
                   (?s: <\? .*? \?> ) |              # processing instruction
                   $nested_tags/ix;                   # nested tags

    while ($str =~ m/($match)/g) {
        my $whole_tag = $1;
        my $sec_start = pos $str;
        my $tag_start = $sec_start - length $whole_tag;
        if ($pos < $tag_start) {
            push @tokens, ['text', substr($str, $pos, $tag_start - $pos)];
        }
        push @tokens, ['tag', $whole_tag];
        $pos = pos $str;
    }
    push @tokens, ['text', substr($str, $pos, $len - $pos)] if $pos < $len;
    \@tokens;
}


sub _Outdent {
#
# Remove one level of line-leading tabs or spaces
#
	my $text = shift || return '';

	$text =~ s/^(\t|[ ]{1,$g_tab_width})//gm;
	return $text;
}


sub _Detab {
#
# Cribbed from a post by Bart Lateur:
# <http://www.nntp.perl.org/group/perl.macperl.anyperl/154>
#
	my $text = shift || return '';

	$text =~ s{(.*?)\t}{$1.(' ' x ($g_tab_width - length($1) % $g_tab_width))}ge;
	return $text;
}


1;

__END__


=pod

=head1 NAME

B<Markdown>


=head1 SYNOPSIS

B<Markdown.pl> [ B<--html4tags> ] [ B<--version> ] [ B<-shortversion> ]
    [ I<file> ... ]


=head1 DESCRIPTION

Markdown is a text-to-HTML filter; it translates an easy-to-read /
easy-to-write structured text format into HTML. Markdown's text format
is most similar to that of plain text email, and supports features such
as headers, *emphasis*, code blocks, blockquotes, and links.

Markdown's syntax is designed not as a generic markup language, but
specifically to serve as a front-end to (X)HTML. You can  use span-level
HTML tags anywhere in a Markdown document, and you can use block level
HTML tags (like <div> and <table> as well).

For more information about Markdown's syntax, see:

    http://daringfireball.net/projects/markdown/


=head1 OPTIONS

Use "--" to end switch parsing. For example, to open a file named "-z", use:

	Markdown.pl -- -z

=over 4


=item B<--html4tags>

Use HTML 4 style for empty element tags, e.g.:

    <br>

instead of Markdown's default XHTML style tags, e.g.:

    <br />


=item B<-v>, B<--version>

Display Markdown's version number and copyright information.


=item B<-s>, B<--shortversion>

Display the short-form version number.


=back



=head1 BUGS

To file bug reports or feature requests (other than topics listed in the
Caveats section above) please send email to:

    support@daringfireball.net

Please include with your report: (1) the example input; (2) the output
you expected; (3) the output Markdown actually produced.


=head1 VERSION HISTORY

	1.0:
	
	+	Blockquote contents are once again indented by two spaces,
		and `<pre>` content is special-cased.

	1.0fc2:
	
	+	Disabled the 'use utf8' pragma, which caused crashes for people
		running Markdown on Perl 5.6.1.

	+	Fixed a couple of bugs in _DoLists() and _ProcessListItems() that
		caused unordered lists starting with `+` or `-` to be turned into
		*ordered* lists.
	
	+	Added to the list of block-level HTML tags:

			noscript, form, fieldset, iframe, math
	
	+	Fixed an odd bug where, with input like this:

			> This line starts the blockquote
			* This list is part of the quote.
			* Second item.
			
			This paragraph is not part of the blockquote.

		The trailing paragraph was incorrectly included in the
		blockquote. (The solution was to add an extra "\n" after
		lists.)
	
	+	The contents of `<blockquote>` tags are no longer indented
		in the HTML output. It made the source look neater, but
		screwed with any `<pre>` blocks in the blockquote.
	
	+	When running under MT 3.0 or later, now displays version number
		in the Markdown info on the main screen.


	1.0fc1:
	
	+	Added some MT 3.0 stuff to register the plug-in in the MT web UI.
		This should not prevent Markdown from running under MT 2.6.

	+	Greatly simplified the rules for code blocks. No more colons
		necessary; if it's indented (4 spaces or 1 tab), it's a code block.
	
	+	Unordered list items can now be denoted by any of the following
		bullet markers: [*+-]
	
	+	_DoCodeSpans() now uses a much simpler regex pattern. Thanks to
		Michel Fortin for the patch.

	*	s/"/&quot;/g  to fix literal quotes within title attributes.

	1.0b9:

	*	s/"/&quot;/g  to fix literal quotes within img alt attributes.

	1.0b8:

	*	Tweaked file slurping syntax.

	*	Added 'math' tags to block-level tag patterns in _HashHTMLBlocks().
		Please disregard all the 'math'-tag related items in 1.0b7.
		
	*	Commented out some vestigial code in _EscapeSpecialChars()

	1.0b7:

	*	Added 'math' to $tags_to_skip pattern, for MathML users.

	*	Tweaked regex for identifying HTML entities in
		_EncodeAmpsAndAngles(), so as to allow for the very long entity
		names used by MathML. (Thanks to Jacques Distler for the patch.)

	*	_DoCodeSpans() now uses 'no strict' inside the ??{} construct
		in the regex pattern, which (the addition of 'no strict') allows
		us to use $backtick_count as an undeclared variable. Perl 5.8.4
		complains without a 'my' here under 'use strict', but earlier
		versions of Perl *won't* allow 'my' here. Bizarrely, the
		opposite is true of 'local', which works fine under Perl 5.6.1 -
		5.8.3, but doesn't work under Perl 5.8.4.
	
	*	All the internal subroutines now return an empty string if
		called without a text parameter. It's my hope that this will
		let Markdown.pl work better under Perl 5.6.0.

	1.0b6:

	*	<MTMarkdownOptions> is now a container tag.

	*	"raw" mode for plaintext output in MT, using
		MarkdownOptions container tag:

			<MTMarkdownOptions output='raw'>
			...
			</MTMarkdownOptions>

	*	Changed name of '--htmltags' CLI switch to '--html4tags'

	1.0b5: 

	*	If Markdown() is called without a string parameter, it now
		returns an empty string. Previously, it'd generate warnings.
		This should never happen, but there's no harm in safeguarding
		against it.

	*	Workaround for supporting <ins> and <del> as block-level tags.
		This only works if the start and end tags are on lines by
		themselves.

	*	Three or more underscores can now be used for horizontal rules.

	*	Lines containing only whitespace are trimmed from blockquotes.

	*	You can now optionally wrap URLs with angle brackets -- like so:
		`<http://example.com>` -- in link definitions and inline links and
		images.

	*	`_` and `*` characters in links and images are no longer escaped
		as HTML entities. Instead, we use the ridiculous but effective MD5
		hashing trick that's used to hide these characters elsewhere. The
		end result is that the HTML output uses the literal `*` and `_`
		characters, rather than the ugly entities.


	1.0b4: Thu 25 Mar 2004

	*	Fixed bug where a paragraph with multiple inline links or images
		-- i.e. [links like this](url "title") -- parsed incorrectly. The
		regex to match title strings was greedy, but shouldn't have been.

	*	Much improved Blosxom interface: no longer processes Blosxom
		titles; now offers optional integration with meta plug-in, so that
		one can specify Markdown on a per-post basis. Thanks to Jason
		Clark <http://jclark.org/weblog/>.

	*	Ampersands in defined links are now encoded as `&amp;` when
		necessary. E.g., if you define this:

			[1]: /foo&bar

		the resulting href attribute will point to "/foo&amp;bar"

	*	Implicit reference ID shortcut is now hooked up for img's:

			![alt text][]

	*	Markdown now allows for a newline break between [link text]
		[id], as in this sentence. (In both links and images.)

	*	Underscores and asterisks within automatic links no longer show
		up in the output as MD5 hash values.



	1.0b3: Fri 12 Mar 2004

	*	Fixed tiny bug where link and image id references were
		being treated case sensitively.



	1.0b2: Fri 12 Mar 2004

	*	Fixed bug in code spans where ampersands were getting
		double-encoded.

	*	Lines with nothing but ">" characters (i.e. blank
		lines in a blockquote) aren't stripped until we're
		actually processing blockquotes. This makes it possible
		to include a line with nothing but a ">" in a code
		block now.

	*	Fixed a minor parsing glitch with inline HTML blocks which
		have trailing spaces or tabs after the closing tag. You'd
		end up with an empty `<p></p>` after the tag.

	*	Markdown now clears its hash table of defined link references
		at the beginning of each article it processes. This solves
		a bug where links defined in article A could be "seen" in
		article B if both both articles appeared on the same page
		(e.g. an index page that displays the most recent entries).



    1.0b1: Tue 9 Mar 2004

        Initial public release.



=head1 AUTHOR

    John Gruber
    http://daringfireball.net


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2004 John Gruber   
<http://daringfireball.net/>   
All rights reserved.

Markdown is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

Markdown is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

=cut

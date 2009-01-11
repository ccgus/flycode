<?php
/**
 * Wikka Formatting Engine
 * 
 * This is the main formatting engine used by Wikka to parse wiki markup and render valid XHTML.
 * 
 * @package Formatters
 * @version $Id$
 * @license http://www.gnu.org/copyleft/gpl.html GNU General Public License
 * @filesource
 *
 * @author {@link http://wikkawiki.org/JsnX Jason Tourtelotte}
 * @author {@link http://wikkawiki.org/DotMG Mahefa Randimbisoa}
 * @author {@link http://wikkawiki.org/JavaWoman Marjolein Katsma}
 * @author {@link http://wikkawiki.org/NilsLindenberg Nils Lindenberg} (code cleanup)
 * @author {@link http://wikkawiki.org/DarTar Dario Taraborelli} (grab handler and filename support for codeblocks)
 * 
 * @uses	Wakka::htmlspecialchars_ent()
 * 
 * @todo		add support for formatter plugins;
 * @todo		use a central RegEx library #34;
 */

// i18n strings
if (!defined('GRABCODE_BUTTON_VALUE')) define('GRABCODE_BUTTON_VALUE', 'Grab');
if (!defined('GRABCODE_BUTTON_TITLE')) define('GRABCODE_BUTTON_TITLE', 'Download %s');

// code block patterns
if (!defined('PATTERN_OPEN_BRACKET')) define('PATTERN_OPEN_BRACKET', '\(');
if (!defined('PATTERN_FORMATTER')) define('PATTERN_FORMATTER', '([^;\)]+)');
if (!defined('PATTERN_LINE_NUMBER')) define('PATTERN_LINE_NUMBER', '(;(\d*?))?');
if (!defined('PATTERN_FILENAME')) define('PATTERN_FILENAME', '(;([^\)\x01-\x1f\*\?\"<>\|]*)([^\)]*))?');
if (!defined('PATTERN_CLOSE_BRACKET')) define('PATTERN_CLOSE_BRACKET', '\)');
if (!defined('PATTERN_CODE')) define('PATTERN_CODE', '(.*)');

// Note: all possible formatting tags have to be in a single regular expression for this to work correctly.

if (!function_exists("wakka2callback")) # DotMG [many lines] : Unclosed tags fix!
{
	function wakka2callback($things)
	{
		$thing = $things[1];
		$result='';

		static $oldIndentLevel = 0;
		static $oldIndentLength= 0;
		static $indentClosers = array();
		static $newIndentSpace= array();
		static $br = 1;
		static $trigger_bold = 0;
		static $trigger_italic = 0;
		static $trigger_underline = 0;
		static $trigger_monospace = 0;
		static $trigger_notes = 0;
		static $trigger_strike = 0;
		static $trigger_inserted = 0;
		static $trigger_deleted = 0;
		static $trigger_floatl = 0;
		static $trigger_keys = 0;
		static $trigger_strike = 0;
		static $trigger_inserted = 0;
		static $trigger_center = 0;
		static $trigger_l = array(-1, 0, 0, 0, 0, 0);
		static $output = '';
		static $valid_filename = '';
		static $invalid = '';

		global $wakka;

		if ((!is_array($things)) && ($things == 'closetags'))
		{
			if ($trigger_strike % 2) echo ('</span>');
			if ($trigger_notes % 2) echo ('</span>');
			if ($trigger_inserted % 2) echo ('</span>');
			if ($trigger_underline % 2) echo('</span>');
			if ($trigger_floatl % 2) echo ('</div>');
			if ($trigger_center % 2) echo ('</div>');
			if ($trigger_italic % 2) echo('</em>');
			if ($trigger_monospace % 2) echo('</tt>');
			if ($trigger_bold % 2) echo('</strong>');
			for ($i = 1; $i<=5; $i ++)
				if ($trigger_l[$i] % 2) echo ("</h$i>");
			$trigger_bold = $trigger_center = $trigger_floatl = $trigger_inserted = $trigger_deleted = $trigger_italic = $trigger_keys = 0;
			$trigger_l = array(-1, 0, 0, 0, 0, 0);
			$trigger_monospace = $trigger_notes = $trigger_strike = $trigger_underline = 0;
			return;
		}
		// convert HTML thingies
		if ($thing == "<")
			return "&lt;";
		else if ($thing == ">")
			return "&gt;";
		// float box left
		else if ($thing == "<<")
		{
			return (++$trigger_floatl % 2 ? "<div class=\"floatl\">\n" : "\n</div>\n");
		}
		// float box right
		else if ($thing == ">>")
		{
			return (++$trigger_floatl % 2 ? "<div class=\"floatr\">\n" : "\n</div>\n");
		}
		// clear floated box
		else if ($thing == "::c::")
		{
			return ("<div class=\"clear\">&nbsp;</div>\n");
		}
		// keyboard
		else if ($thing == "#%")
		{
			return (++$trigger_keys % 2 ? "<kbd class=\"keys\">" : "</kbd>");
		}
		// bold
		else if ($thing == "**")
		{
			return (++$trigger_bold % 2 ? "<strong>" : "</strong>");
		}
		// italic
		else if ($thing == "//")
		{
			return (++$trigger_italic % 2 ? "<em>" : "</em>");
		}
		// underlinue
		else if ($thing == "__")
		{
			return (++$trigger_underline % 2 ? "<span class=\"underline\">" : "</span>");
		}
		// monospace
		else if ($thing == "##")
		{
			return (++$trigger_monospace % 2 ? "<tt>" : "</tt>");
		}
		// notes
		else if ($thing == "''")
		{
			return (++$trigger_notes % 2 ? "<span class=\"notes\">" : "</span>");
		}
		// strikethrough
		else if ($thing == "++")
		{
			return (++$trigger_strike % 2 ? "<span class=\"strikethrough\">" : "</span>");
		}
		// additions
		else if ($thing == "&pound;&pound;")
		{
			return (++$trigger_inserted % 2 ? "<span class=\"additions\">" : "</span>");
		}
		// deletions
		else if ($thing == "&yen;&yen;")
		{
			return (++$trigger_deleted % 2 ? "<span class=\"deletions\">" : "</span>");
		}
		// center
		else if ($thing == "@@")
		{
			return (++$trigger_center % 2 ? "<div class=\"center\">\n" : "\n</div>\n");
		}
		// urls
		else if (preg_match("/^([a-z]+:\/\/\S+?)([^[:alnum:]^\/])?$/", $thing, $matches))
		{
			$url = $matches[1];
			/* Inline images are disabled for security reason, use {{image action}} #142
			But if you still need this functionality, update this file like below
			if (preg_match("/\.(gif|jpg|png|svg)$/si", $url)) {
				return '<img src="'.$wakka->Link($url).'" alt="image" />'.$wakka->htmlspecialchars_ent($matches[2]);
			} else */
			// Mind Mapping Mod
			if (preg_match("/\.(mm)$/si", $url)) { #145
				return $wakka->Action("mindmap ".$url);
			} else
				return $wakka->Link($url).$matches[2];
		}
		// header level 5
		else if ($thing == "==")
		{
				$br = 0;
				return (++$trigger_l[5] % 2 ? "<h5>" : "</h5>\n");
		}
		// header level 4
		else if ($thing == "===")
		{
				$br = 0;
				return (++$trigger_l[4] % 2 ? "<h4>" : "</h4>\n");
		}
		// header level 3
		else if ($thing == "====")
		{
				$br = 0;
				return (++$trigger_l[3] % 2 ? "<h3>" : "</h3>\n");
		}
		// header level 2
		else if ($thing == "=====")
		{
				$br = 0;
				return (++$trigger_l[2] % 2 ? "<h2>" : "</h2>\n");
		}
		// header level 1
		else if ($thing == "======")
		{
				$br = 0;
				return (++$trigger_l[1] % 2 ? "<h1>" : "</h1>\n");
		}
		// forced line breaks
		else if ($thing == "---")
		{
			return "<br />";
		}
		// escaped text
		else if (preg_match("/^\"\"(.*)\"\"$/s", $thing, $matches))
		{
			$allowed_double_doublequote_html = "raw";
			if ($allowed_double_doublequote_html == 'safe')
			{
				$filtered_output = $wakka->ReturnSafeHTML($matches[1]);
				return $filtered_output;
			}
			elseif ($allowed_double_doublequote_html == 'raw')
			{
				return $matches[1];
			}
			else
			{
				return $wakka->htmlspecialchars_ent($matches[1]);
			}
		}
		// code text
		else if (preg_match("/^%%(.*?)%%$/s", $thing, $matches))
		{
			/*
			* Note: this routine is rewritten such that (new) language formatters
			* will automatically be found, whether they are GeSHi language config files
			* or "internal" Wikka formatters.
			* Path to GeSHi language files and Wikka formatters MUST be defined in config.
			* For line numbering (GeSHi only) a starting line can be specified after the language
			* code, separated by a ; e.g., %%(php;27)....%%.
			* Specifying >= 1 turns on line numbering if this is enabled in the configuration.
			* An optional filename can be specified as well, e.g. %%(php;27;myfile.php)....%%
			* This filename will be used by the grabcode handler.			
			*/
			$output = ''; //reinitialize variable
			$code = $matches[1];
			// if configuration path isn't set, make sure we'll get an invalid path so we
			// don't match anything in the home directory
			$geshi_hi_path = isset($wakka->config['geshi_languages_path']) ? $wakka->config['geshi_languages_path'] : '/:/';
			$wikka_hi_path = isset($wakka->config['wikka_highlighters_path']) ? $wakka->config['wikka_highlighters_path'] : '/:/';
			// check if a language (and an optional starting line or filename) has been specified
			if (preg_match('/^'.PATTERN_OPEN_BRACKET.PATTERN_FORMATTER.PATTERN_LINE_NUMBER.PATTERN_FILENAME.PATTERN_CLOSE_BRACKET.PATTERN_CODE.'$/s', $code, $matches))
			{
				list(, $language, , $start, , $filename, $invalid, $code) = $matches;
			}
			// get rid of newlines at start and end (and preceding/following whitespace)
			// Note: unlike trim(), this preserves any tabs at the start of the first "real" line
			$code = preg_replace('/^\s*\n+|\n+\s*$/','',$code);
			
			// check if GeSHi path is set and we have a GeSHi highlighter for this language
#			if (isset($language) && isset($wakka->config['geshi_path']) && file_exists($geshi_hi_path.'/'.$language.'.php'))
			if (isset($language) && isset($wakka->config['geshi_path']) && file_exists($geshi_hi_path.DIRECTORY_SEPARATOR.$language.'.php')) #89
			{
				// check if specified filename is valid and generate code block header
				if (isset($filename) && strlen($filename) > 0 && strlen($invalid) == 0) # #34 TODO: use central regex library for filename validation
				{
					$valid_filename = $filename;
					// create code block header
					$output .= '<div class="code_header">';
					// display filename and start line, if specified
					$output .= $filename;
					if (strlen($start)>0)
					{
						$output .= ' (line '.$start.')';
					}
					$output .= '</div>'."\n";
				}
				// use GeSHi for highlighting
				$output .= $wakka->GeSHi_Highlight($code, $language, $start);
			}
			// check Wikka highlighter path is set and if we have an internal Wikka highlighter
#			elseif (isset($language) && isset($wakka->config['wikka_formatter_path']) && file_exists($wikka_hi_path.'/'.$language.'.php') && 'wakka' != $language)
			elseif (isset($language) && isset($wakka->config['wikka_formatter_path']) && file_exists($wikka_hi_path.DIRECTORY_SEPARATOR.$language.'.php') && 'wakka' != $language) #89
			{
				// use internal Wikka highlighter
				$output = '<div class="code">'."\n";
				$output .= $wakka->Format($code, $language);
				$output .= "</div>\n";
			}
			// no language defined or no formatter found: make default code block;
			// IncludeBuffered() will complain if 'code' formatter doesn't exist
			else
			{
				$output = '<pre class="code">'."\n";
				$output .= $code; //$wakka->Format($code, 'code');
				$output .= "</pre>\n";
			}

			// display grab button if option is set in the config file
			if ($wakka->config['grabcode_button'] == '1')
			{
				$output .= $wakka->FormOpen("grabcode");
				// build form
				$output .= '<input type="submit" class="grabcode" name="save" value="'.GRABCODE_BUTTON_VALUE.'" title="'.rtrim(sprintf(GRABCODE_BUTTON_TITLE, $valid_filename)).'" />';
				$output .= '<input type="hidden" name="filename" value="'.urlencode($valid_filename).'" />';
				$output .= '<input type="hidden" name="code" value="'.urlencode($code).'" />';
				$output .= $wakka->FormClose();
			}
			// output
			return $output;
		}
		// forced links
		// \S : any character that is not a whitespace character
		// \s : any whitespace character
		else if (preg_match("/^\[\[(\S*)(\s+(.+))?\]\]$/s", $thing, $matches))		# recognize forced links across lines
		{
			list (, $url, , $text) = $matches;
			if ($url)
			{
				//if ($url!=($url=(preg_replace("/@@|&pound;&pound;||\[\[/","",$url))))$result="</span>";
				if (!$text) $text = $url;
				//$text=preg_replace("/@@|&pound;&pound;|\[\[/","",$text);
				return $result.$wakka->Link($url, "", $text);
			}
			else
			{
				return "";
			}
		}
		// indented text
		elseif (preg_match("/\n([\t~]+)(-|&|([0-9a-zA-Zƒ÷‹ﬂ‰ˆ¸]+)\))?(\n|$)/s", $thing, $matches))
		{
			// new line
			$result .= ($br ? "<br />\n" : "\n");

			// we definitely want no line break in this one.
			$br = 0;

			// find out which indent type we want
			$newIndentType = $matches[2];
			if (!$newIndentType) { $opener = "<div class=\"indent\">"; $closer = "</div>"; $br = 1; }
			elseif ($newIndentType == "-") { $opener = "<ul><li>"; $closer = "</li></ul>"; $li = 1; }
			elseif ($newIndentType == "&") { $opener = "<ul class=\"thread\"><li>"; $closer = "</li></ul>"; $li = 1; } #inline comments
			else { $opener = "<ol type=\"". substr($newIndentType, 0, 1)."\"><li>"; $closer = "</li></ol>"; $li = 1; }

			// get new indent level
			$newIndentLevel = strlen($matches[1]);
			if ($newIndentLevel > $oldIndentLevel)
			{
				for ($i = 0; $i < $newIndentLevel - $oldIndentLevel; $i++)
				{
					$result .= $opener;
					array_push($indentClosers, $closer);
				}
			}
			else if ($newIndentLevel < $oldIndentLevel)
			{
				for ($i = 0; $i < $oldIndentLevel - $newIndentLevel; $i++)
				{
					$result .= array_pop($indentClosers);
				}
			}

			$oldIndentLevel = $newIndentLevel;

			if (isset($li) && !preg_match("/".str_replace(")", "\)", $opener)."$/", $result))
			{
				$result .= "</li><li>";
			}

			return $result;
		}
		// new lines
		else if ($thing == "\n")
		{
			// if we got here, there was no tab in the next line; this means that we can close all open indents.
			$c = count($indentClosers);
			for ($i = 0; $i < $c; $i++)
			{
				$result .= array_pop($indentClosers);
				$br = 0;
			}
			$oldIndentLevel = 0;
			$oldIndentLength= 0;
			$newIndentSpace=array();

			$result .= ($br ? "<br />\n" : "\n");
			$br = 1;
			return $result;
		}
		// Actions
		else if (preg_match("/^\{\{(.*?)\}\}$/s", $thing, $matches))
		{
            return $matches[1];
			//if ($matches[1])
			//	return $wakka->Action($matches[1]);
			//else
			//	return "{{}}";
		}
		// interwiki links!
		else if (preg_match("/^[A-Zƒ÷‹][A-Za-zƒ÷‹ﬂ‰ˆ¸]+[:]\S*$/s", $thing))
		{
			return $wakka->Link($thing);
		}
		// wiki links!
		else if (preg_match("/^[A-Zƒ÷‹]+[a-zﬂ‰ˆ¸]+[A-Z0-9ƒ÷‹][A-Za-z0-9ƒ÷‹ﬂ‰ˆ¸]*$/s", $thing))
		{
			return $wakka->Link($thing);
		}
		// separators
		else if (preg_match("/-{4,}/", $thing, $matches))
		{
			// TODO: This could probably be improved for situations where someone puts text on the same line as a separator.
			//	   Which is a stupid thing to do anyway! HAW HAW! Ahem.
			$br = 0;
			return "<hr />\n";
		}
		// mind map xml
		else if (preg_match("/^<map.*<\/map>$/s", $thing))
		{
			return $wakka->Action("mindmap ".$wakka->Href()."/mindmap.mm");
		}
		// if we reach this point, it must have been an accident.
		return $thing;
	}
}

$text = str_replace("\r\n", "\n", $text);

// replace 4 consecutive spaces at the beginning of a line with tab character
// $text = preg_replace("/\n[ ]{4}/", "\n\t", $text); // moved to edit.php

if ($this->method == "show") $mind_map_pattern = "<map.*?<\/map>|"; else $mind_map_pattern = "";

$text = preg_replace_callback(
	"/(".
	"%%.*?%%|".																				# code
	"\"\".*?\"\"|".																			# literal
	$mind_map_pattern.
	"\[\[[^\[]*?\]\]|".																		# forced link
	"-{4,}|---|".																			# separator (hr)
	"\b[a-z]+:\/\/\S+|".																	# URL
	"\*\*|\'\'|\#\#|\#\%|@@|::c::|\>\>|\<\<|&pound;&pound;|&yen;&yen;|\+\+|__|<|>|\/\/|".	# Wiki markup
	"======|=====|====|===|==|".															# headings
	"\n([\t~]+)(-|&|[0-9a-zA-Z]+\))?|".														# indents and lists
	"\{\{.*?\}\}|".																			# action
	"\b[A-Zƒ÷‹][A-Za-zƒ÷‹ﬂ‰ˆ¸]+[:](?![=_])\S*\b|".											# InterWiki link
	"\b([A-Zƒ÷‹]+[a-zﬂ‰ˆ¸]+[A-Z0-9ƒ÷‹][A-Za-z0-9ƒ÷‹ﬂ‰ˆ¸]*)\b|".								# CamelWords
	"\n".																					# new line
	")/ms", "wakka2callback", $text);

// we're cutting the last <br />
$text = preg_replace("/<br \/>$/","", $text);

    echo ("<style type=\"text/css\">
          body {
          font-family: \"Lucida Grande\", Verdana, Arial, sans-serif;
          }
    </style>");
    

echo ($text);
wakka2callback('closetags');

?>

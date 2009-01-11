#!/usr/bin/php
<?php

class WakkaCL {
    
    function Link($tag, $method='', $text='', $track=TRUE, $escapeText=TRUE, $title='') {
        return $tag;
    }
    
    function Run($text) {
        
        $wakka = $this;
        
        ob_start();
        include("wakka.php");
        $output = ob_get_contents();
        ob_end_clean();
        
        return $output;
    }
}

$wakka = new WakkaCL();

$input = stream_get_contents(fopen($argv[1], "r"));

$output = $wakka->Run($input);

$outputStream = fopen($argv[1] . ".html", "w");

fwrite($outputStream, $output);

fclose ($outputStream);


?>
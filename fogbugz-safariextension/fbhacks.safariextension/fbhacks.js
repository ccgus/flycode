function anythingBut(s, l) {
    var idx = 0;
    while (idx < s.length) {
        if (s.charAt(idx) != l) {
            return false;
        }
        idx++;
    }
    return true;
}

function rewrap(s, len) {
    
    var ret = "";
    s = s.replace("\r\n", "\n");
    s = s.replace("\r", "\n");
    
    var ss = s.split("\n");
    
    for (var sidx = 0; sidx < ss.length; sidx++) {
        var line = ss[sidx];
        
        if (!line.length) {
            ret = ret +  "\n";
            continue;
        }
        
        var idx = 0;
        while ((idx < line.length) && (line.charAt(idx) == '>')) {
            idx++;
        }
        
        var pre = "";
        for (j = 0; j < idx; j++) {
            pre = pre + ">";
        }
        
        var oldLine = line.substring(idx);
        var newLine = pre;
        var words = oldLine.split(String.fromCharCode(32));
        
        for (var wordIdx = 0; wordIdx < words.length; wordIdx++) {
            
            var word = words[wordIdx];
            
            if (newLine.length + word.length > len) {
                ret = ret + newLine + "\n"
                newLine = pre;
            }
            
            if (word.length && !anythingBut(newLine, '>')) {
                newLine = newLine + " ";
            }
            
            newLine = newLine + word;
        }
        
        ret = ret + newLine + "\n";
    }
    
    return ret;
}

function setupReply() {
    var msg      = document.getElementById("sEventReply").value;
    
    var sigIdx   = msg.indexOf("-----Original Message-----")
    var sig      = msg.substring(0, sigIdx);
    
    var restIdx  = msg.indexOf("\n\n", sigIdx);
    var rest     = msg.substring(restIdx);
    
    rest         = rest.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    
    var fromIdx  = msg.indexOf("From: ");
    var fromIdxs = msg.indexOf("\n", fromIdx);
    var from     = msg.substring(fromIdx + 6, fromIdxs);
    var newMsg   = from + " wrote:\n" + rest + "\n\n" + sig;
    
    newMsg       = newMsg.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    
    document.getElementById("sEventReply").value = rewrap(newMsg, 72);
    document.getElementById("sEventReply").focus();
}

if (window.top === window) {

    // command=reply
    var s = window.location + "";
    if (s.indexOf("command=reply") > 0) {
        setupReply();
    }
}
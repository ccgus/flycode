//
//  maindocs.h
//  MYNetwork
//
//  Created by Jens Alfke on 5/24/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//
// This file just contains the Doxygen comments that generate the main (index.html) page content.


/*! \mainpage MYNetwork: Mooseyard Networking Library, With BLIP Protocol Implementation
 
    <center><b>By <a href="/Jens/">Jens Alfke</a></b></center>

    <img src="BLIP.png">

\section intro_sec Introduction
 
    MYNetwork is a set of Objective-C networking classes for Cocoa applications on Mac OS X.
    It consists of:
    <ul>
    <li>Networking utility classes (presently only IPAddress);
    <li>A generic TCP client/server implementation,
        useful for implementing your own network protocols; (see TCPListener and TCPConnection)
    <li>An implementation of <a href="#blipdesc">BLIP</a>, a lightweight network protocol I've invented as an easy way
        to send request and response messages between peers. (see BLIPListener, BLIPConnection, BLIPRequest, etc.)
    </ul>
 
\section license License and Disclaimer
 
 MYNetwork is released under a BSD license, which means you can freely use it in open-source
 or commercial projects, provided you give credit in your documentation or About box.
 
 As I write this (May 2008), MYNetwork is still very much under development. I am using it as the foundation of my own commercial products, at least one of which is currently at about the alpha stage. I'm making changes to this code as I see fit, fairly often.
 
That's good, in that the code is getting real-world use. But it also means that APIs and functionality are subject to change. (Of course, the entire revision tree is always available, so you're free to stick with any revision you like, and even "cherry-pick" desired changes from future ones.)
 
Not all of this code gets thoroughly exercised by my test cases or my applications, so some things may not work. Obviously, this code comes with no warranty nor any guarantee of tech support, though I will try to do my best to help out. Hopefully the source code is clear enough to let you figure out what's going on.
 
If you come across bugs, please tell me about them. If you fix them, I would love to get your fixes and incorporate them. If you add features I would love to know about them, and I will incorporate them if I think they make sense for the project. Thanks!

\section blipdesc What's BLIP?
 
 <table style="background-color: #fff; padding: 5px; float: right" cellspacing=0>
 <tr><td>
 <img src="http://groups.google.com/groups/img/3nb/groups_bar.gif"
 height=26 width=132 alt="Google Groups">
 </td></tr>
 <tr><td style="padding-left: 5px;font-size: 125%">
 <b>BLIP Protocol</b>
 </td></tr>
 <tr><td style="padding-left: 5px">
 <a href="http://groups.google.com/group/blip-protocol">Visit this group</a>
 </td></tr>
 </table>
 
BLIP is a message-oriented network protocol that lets the two peers on either end of a TCP socket send request and response messages to each other. It's a generic protocol, in that the requests and responses can contain any kind of data you like. 
 
BLIP was inspired by <a
href="http://beepcore.org">BEEP</a> (in fact BLIP stands for "BEEP-LIke Protocol") but is
deliberately simpler and somewhat more limited. That results in a smaller and cleaner implementation, especially since it takes advantage of Cocoa's and CFNetwork's existing support for network streams, SSL and Bonjour. (BLIP is currently a bit under 2,000 lines of code, and the rest of the MYNetwork classes it builds on add up to another 1,500. That's at least an order of magnitude smaller than existing native-code BEEP libraries.)
 
\subsection blipfeatures BLIP Features:

 <ul>
 <li>Each message is very much like a MIME body, as in email or HTTP: it consists of a
blob of data of arbitrary length, plus a set of key/value pairs called "properties". The
properties are mostly ignored by BLIP itself, but clients can use them for metadata about the
body, and for delivery information (i.e. something like BEEP's "profiles".)

<li>Either peer can send a request at any time; there's no notion of "client" and "server" roles.
 
<li> Multiple messages can be transmitted simultaneously in the same direction over the same connection, so a very long
message does not block any other messages from being delivered. This means that message ordering
is a bit looser than in BEEP or HTTP 1.1: the receiver will see the beginnings of messages in the
same order in which the sender posted them, but they might not <i>end</i> in that same order. (For
example, a long message will take longer to be delivered, so it may finish after messages that
were begun after it.)

<li>The sender can indicate whether or not a message needs to be replied to; the response is tagged with the
identity of the original message, to make it easy for the sender to recognize. This makes it
straighforward to implement RPC-style (or REST-style) interactions. (Responses
cannot be replied to again, however.)

<li>A message can be flagged as "urgent". Urgent messages are pushed ahead in the outgoing queue and
get a higher fraction of the available bandwidth.

<li>A message can be flagged as "compressed". This runs its body through the gzip algorithm, ideally
making it faster to transmit. (Common markup-based data formats like XML and JSON compress
extremely well, at ratios up to 10::1.) The message is decompressed on the receiving end,
invisibly to client code.
 
<li>The implementation supports SSL connections (with optional client-side certificates), and Bonjour service advertising.
</ul>
  
\section config Configuration
 
    MYNetwork requires Mac OS X 10.5 or later, since it uses Objective-C 2 features like
    properties and for...in loops.
 
    MYNetwork uses my <a href="/hg/hgwebdir.cgi/MYUtilities">MYUtilities</a> library. You'll need to have downloaded that library, and added
    the necessary source files and headers to your project. See the MYNetwork Xcode project,
    which contains the minimal set of MYUtilities files needed to build MYUtilities. (That project
    has its search paths set up to assume that MYUtilities is in a directory next to MYNetwork.)

\section download How To Get It

    <ul>
    <li><a href="/hg/hgwebdir.cgi/MYNetwork/archive/tip.zip">Download the current source code</a>
    <li>To check out the source code using <a href="http://selenic.com/mercurial">Mercurial</a>:
    \verbatim hg clone /hg/hgwebdir.cgi/MYNetwork/ MYNetwork \endverbatim
    <li>As described above, you'll also need to download or check out <a href="/hg/hgwebdir.cgi/MYUtilities">MYUtilities</a> and put it in 
    a directory next to MYNetwork.
    </ul>

    Or if you're just looking:

    <ul>
    <li><a href="/hg/hgwebdir.cgi/MYNetwork/file/tip">Browse the source code</a>
    <li><a href="annotated.html">Browse the class documentation</a>
    </ul>
 
    There isn't any conceptual documentation yet, beyond what's in the API docs, but you can 
    <a href="/hg/hgwebdir.cgi/MYNetwork/file/tip/BLIP/Demo/">look
    at the sample BLIPEcho client and server</a>, which are based on Apple's 
    <a href="http://developer.apple.com/samplecode/CocoaEcho/index.html">CocoaEcho</a> sample code.
 
 */

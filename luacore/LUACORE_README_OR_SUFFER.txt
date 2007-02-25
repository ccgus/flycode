LuaCore is a project, based on a number of other projects.

LuaCore wouldn't have been possible without LuaObjCBridge, a framework written
by Tom McClean and available at:
http://www.pixelballistics.com/Software/LuaObjCBridge
So let's hear a round of applause for him: *clap* *clap* *clap*

GOALS:
The purpose of this framework is to make it really easy to setup and run Lua
scripts inside Objective-C/Cocoa applications on the latest version of Mac OS X.

The guy who wrote this framework (that's me, August 'Gus' Mueller) is an
admitted Lua newbie, so if you see something that could be improved let him know
at gus@flyingmeat.com.  He's fine with harsh criticism as well, but be aware
that he always has the liberty of playing the fool and saying "Hey, it's not
like I got a CS degree.  Who's this XOR dude anyway?"

CONTACT:
http://gusmueller.com/lua/
gus@flyingmeat.com

STUFF:
The LuaObjCBridge has been modified quite a bit.  Since I don't care about
GNUStep in the slightest bit, I've taken everything out that was #ifdef'd with
LUA_OBJC_USE_FOUNDATION_INSTEAD_OF_RUNTIME to make it easier to read.

LICENSE:
Copyright (c) 2006, Flying Meat Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list
of conditions and the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

Neither the name of the Flying Meat nor the names of its contributors may be
used to endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

It would also be cool if you put something in the about box that you're using
the LuaCore framework.

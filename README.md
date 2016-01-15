Name
====

lua-resty-danmaku - Danmaku server based on the ngx_lua cosocket API

Table of Contents
=================
<!-- MarkdownTOC -->

- Description
- Synopsis
- Sample configuration
- TODO
- Copyright and License
- See Also

<!-- /MarkdownTOC -->


Description
===========

This Lua library is a [Danmaku](https://zh.wikipedia.org/zh/%E8%A7%86%E9%A2%91%E5%BC%B9%E5%B9%95) server based on ngx_lua module. Currently this server can only work on Websocket protocol.

Note that at least [ngx_lua 0.10.0](https://github.com/chaoslawful/lua-nginx-module/tags) or [ngx_openresty 1.9.7.2](http://openresty.org/#Download) is required. Also, [lua-resty-websocket](https://github.com/openresty/lua-resty-websocket) is required to accept Websocket connections.

Synopsis
========

[Back to TOC](#table-of-contents)


Sample configuration
========

```
server {
        listen 80;
        listen 443 ssl http2;

        location ~ /danmaku/(\d+) {
            set $liveid $1;
            set $keep_alive_timeout 30000;
            content_by_lua "
                local dmk = require('resty.danmaku')
                dmk.run()
            ";
        }

        location = /danmaku/stat {
             content_by_lua "
                local u = require 'resty.danmaku.stat'
                require 'resty.danmaku.broadcaster'
                ngx.say(u._get_stat())
             ";
        }
}
```

[Back to TOC](#table-of-contents)


TODO
====

- HTTP pooling support
- TCP protocol support

[Back to TOC](#table-of-contents)


Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2016, by fffonion <fffonion@gmail.com>.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule

[Back to TOC](#table-of-contents)


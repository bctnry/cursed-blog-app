# cursed blog app

> awk is a serious programming language...
>
> awk is a serious programming language...
>
> awk is a serious programming language...
>
> recfile is a serious database...
>
> recfile is a serious database...
>
> recfile is a serious database...

An exercise of the LAR stack

LAR: lighttpd + awk + recutils

NOTE: requires gawk because we used multi-dimension array.

Security is non-existent.

Code distributed in public domain and is provided here with absolutely no warranty.

Please don't run this in production...

## how to run

+ You need:
  + Go compiler.
  + Recutils and lighttpd installed and ready at PATH.
  
Then:
  
1. Compile the helper command (and you absolutely need this helper command). Run `go build` under `./helper/bcrypt` to build it.
2. Make sure that the following folders exist:
   + ~./db/article~
   + ~./db/comment~
   + ~./db/session~
2. At project root run `lighttpd -D -f ./lighttpd.conf`

### why lighttpd?

This project uses CGI and lighttpd is a very lightweight http server that supports CGI out of the box. If you run Apache you can try to run it that way.

NGINX seems to not have built-in CGI support. Please run it with lighttpd and connect it through reverse proxy.

### why helper command?

+ recutils provide symmetric encryption but no hash which is not suitable for storing password.
+ theoretically you can implement some hash functions purely in awk but it's bloody hard to make a cryptographically safe one.


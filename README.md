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

NOTE: requires gawk because we used ~~multi-dimension array~~ FFI to get bcrypt.

Security is non-existent. Quality is non-existent as well (you can clearly tell this is written someone who has zero experience w/ awk but still chugged along anyway).

Code distributed in public domain and is provided here with absolutely no warranty.

Please don't run this in production...

## how to run

+ You need:
  + A C compiler to compile the gawk_bcrypt extension.
  + GNU awk.
  + Recutils and lighttpd installed and ready at PATH.
  
Then:
  
1. Compile the gawk_bcrypt extension (and you absolutely need this). You can get it at https://github.com/bctnry/gawk-bcrypt .
2. Put the compiled extension (`bcrypt.so`) at the root directory & rename it to `gawk_bcrypt.so` (so that you won't be having chances of mistaking it for something important)
3. Make sure that the following folders exist:
   + `./db/article`
   + `./db/comment`
   + `./db/session`
4. Edit `lighttpd.conf`. The `server.document-root` needs to point to the path of the `wwwroot` folder.
5. At project root run `lighttpd -D -f ./lighttpd.conf`

### why lighttpd?

This project uses CGI and lighttpd is a very lightweight http server that supports CGI out of the box. If you run Apache you can try to run it that way.

NGINX seems to not have built-in CGI support. Please run it with lighttpd and connect it through reverse proxy.

### why extension?

+ recutils provide symmetric encryption but no hash which is not suitable for storing password.
+ theoretically you can implement some hash functions purely in awk but it's bloody hard to make a cryptographically safe one.


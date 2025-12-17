@namespace "cgi"

# this is to be used with lighttpd.

# convert escaped url back to unescaped strings.
# taken from:
#     https://www.gnu.org/software/gawk/manual/gawkinet/html_node/CGI-Lib.html
# with a little bit of modification
function _decode_uri_component(\
	str,\
	hexdigs, i, pre, code1, code2,\
	val, result\
) {
   hexdigs = "123456789abcdef"

   i = index(str, "%")
   if (i == 0) { return str }

   do {
      pre = substr(str, 1, i-1)   # part before %xx
      code1 = substr(str, i+1, 1) # first hex digit
      code2 = substr(str, i+2, 1) # second hex digit
      str = substr(str, i+3)      # rest of string

      code1 = tolower(code1)
      code2 = tolower(code2)
      val = index(hexdigs, code1) * 16 + index(hexdigs, code2)

      result = result pre sprintf("%c", val)
      i = index(str, "%")
   } while (i != 0)
   
   if (length(str) > 0) {
	   result = result str
   }
   return result
}

# sets GET_PARAMS to the params of 
function parse_query(str, out,
					 #local
					 res_1, j, k, v) {
	delete out
	delete res_1
	split(str, res_1, "&")
	for (i in res_1) {
		res_1[i] = _decode_uri_component(res_1[i])
		j = index(res_1[i], "=")
		k = substr(res_1[i], 1, j-1)
		v = substr(res_1[i], j+1)
		k = awk::gensub("+", " ", "g", k)
		v = awk::gensub("+", " ", "g", v)
		out[k] = v
	}
}

function write_http_status(st, ext) {
	printf("Status: %d %s\n", st, ext)
}

function begin_write_http_header() {}
function write_http_header(key, value) {
	printf("%s: %s\n", key, value)
}
function end_write_http_header() {
	printf("\n")
}

function parse_cookie(out,
					  #local
					  l,
					  i, pair, key, val) {
	delete out
	split(ENVIRON["HTTP_COOKIE"], l, ";")
	for (i in l) {
		split(l[i], pair, "=")
		key = pair[1]
		val = pair[2]
		gsub(/^[[:space:]]+/, "", key)
		gsub(/[[:space:]]+$/, "", key)
		gsub(/^[[:space:]]+/, "", val)
		gsub(/[[:space:]]+$/, "", val)
		out[key] = val
	}
}

function is_get_request() { return ENVIRON["REQUEST_METHOD"] == "GET" }
function is_post_request() { return ENVIRON["REQUEST_METHOD"] == "POST" }


#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_user.awk"
@include "../lib/db_session.awk"
@include "../lib/bcrypt_wrapper.awk"
@include "../lib/aux.awk"

BEGIN {
	if (is_get_request()) {
		handle_logout_get()
	} else {
		write_http_status(405, "Method Not Allowed")
	}
}

function handle_logout_get(\
	f, line, username) {
	parse_cookie(COOKIE)
	username = trim_space(COOKIE["username"])
	session = trim_space(COOKIE["session"])
	invalidate_session(ENVIRON["DOCUMENT_ROOT"], username)
	
	write_http_status(302, "Found")
	begin_write_http_header()
	write_http_header("Content-Type", "text/html")
	write_http_header("Set-Cookie", sprintf("username=%s; Max-Age=0", username))
	write_http_header("Set-Cookie", sprintf("session=%s; Max-Age=0", session))
	write_http_header("Location", "/index.awk")
	write_http_header("Content-Length", "0")
	end_write_http_header()
}


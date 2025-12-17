#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_user.awk"
@include "../lib/db_session.awk"
@include "../lib/aux.awk"

BEGIN {
	if (cgi::is_get_request()) {
		handle_logout_get()
	} else {
		cgi::write_http_status(405, "Method Not Allowed")
	}
}

function handle_logout_get(\
	f, line, username) {
	cgi::parse_cookie(COOKIE)
	username = trim_space(COOKIE["username"])
	session = trim_space(COOKIE["session"])
	invalidate_session(ENVIRON["DOCUMENT_ROOT"], username)
	
	cgi::write_http_status(302, "Found")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::write_http_header("Set-Cookie", sprintf("username=%s; Max-Age=0", username))
	cgi::write_http_header("Set-Cookie", sprintf("session=%s; Max-Age=0", session))
	cgi::write_http_header("Location", "/index.awk")
	cgi::write_http_header("Content-Length", "0")
	cgi::end_write_http_header()
}


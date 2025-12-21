#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_article.awk"
@include "../lib/db_session.awk"
@include "../lib/db_comment.awk"
@include "../lib/db_user.awk"
@include "../lib/aux.awk"

BEGIN {
	if (cgi::is_get_request()) {
		handle_page_index_get()
	} else {
		cgi::write_http_status(405, "Method Not Allowed")
	}
}

function handle_component_nav_bar_get() {
	cgi::parse_cookie(COOKIE)
	
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
    
}



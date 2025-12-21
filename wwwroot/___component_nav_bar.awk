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
		handle_component_nav_bar_get()
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
    
	chkses_res = check_session(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], COOKIE["session"])
	if (chkses_res) {
		printf("<div class=\"meta\">logged in as %s. <a hx-get=\"logout.awk\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\">logout</a> ",
			   COOKIE["username"])
		printf("<a hx-get=\"___component_create_article_form.awk\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\">new post</a>")
		get_user(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], user)
		if (user["Role"] == "admin") {
			printf(" <a href=\"admin.awk\">admin</a>")
		}
		printf("</div>")
	} else {
		printf("<div class=\"meta\"><a hx-get=\"___component_login_form.awk\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\">login</a> <a hx-get=\"___component_register_form.awk\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\">register</a></div>")
	}
}


function logged_in() {
    if (length(COOKIE["username"]) <= 0) { return 0; }
    if (length(COOKIE["session"]) <= 0) { return 0; }
    
}


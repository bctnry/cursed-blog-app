#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/db_user.awk"
@include "../lib/db_session.awk"
@include "../lib/aux.awk"
@include "../lib/reclib.awk"

BEGIN {
	if (cgi::is_get_request()) {
		cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
		handle_admin_get()
	} else if (cgi::is_post_request()) {
		BODY = ""
	} else {
		cgi::write_status(405, "Method Not Allowed")
	}
}

{
	if (cgi::is_get_request()) { BODY = BODY $0 "\n" }
}

END {
	if (cgi::is_post_request()) {
		gsub(/\n$/, "", BODY)
		handle_admin_post()
	}
}

function handle_admin_get(\
	f, line) {
	cgi::parse_cookie(COOKIE)
	chkres = check_session(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], COOKIE["session"])
	if (!chkres) {
		cgi::write_http_status(403, "Forbidden")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   403,
				   "Pleasee log in first.",
				   "/login.awk",
				   5))
		return
	}
	if (!get_user(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], user)) {
		cgi::write_http_status(403, "Forbidden")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   403,
				   "Invalid credentials.",
				   "/login.awk",
				   5))
		return
	}
	if (user["Role"] != "admin") {
		cgi::write_http_status(403, "Forbidden")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   403,
				   "No privilege.",
				   "/login.awk",
				   5))
		return
	}
	f = ENVIRON["DOCUMENT_ROOT"] "../templates/admin.html"
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	header("Admin Panel")
	delete data
	printf("%s", template::render_template_file(f, data))
	footer()
}

function header(title) {
	printf("%s", render_header_template(ENVIRON["DOCUMENT_ROOT"], title))
}

function footer() {
	printf("%s", render_footer_template(ENVIRON["DOCUMENT_ROOT"]))
}



#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_user.awk"
@include "../lib/db_session.awk"
@include "../lib/aux.awk"


BEGIN {
	if (cgi::is_get_request()) {
		handle_login_get()
	} else if (cgi::is_post_request()) {
		BODY = ""
	} else {
		cgi::write_http_status(405, "Method Not Allowed")
	}
}

{
	if (cgi::is_post_request()) { BODY = BODY $0 "\n" }
}

END {
	if (cgi::is_post_request()) {
		gsub(/\n$/, "", BODY)
		handle_login_post()
	}
}

function handle_login_get(\
	f, line) {
	
	f = ENVIRON["DOCUMENT_ROOT"] "../templates/login.html"
	
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	
	while(getline line < f) { printf("%s\n", line) }
}

function handle_login_post(chkres,
						   #local
						   username, password, new_session,
						   current_timestamp,
						   line) {
	cgi::parse_query(BODY, POST_PARAMS)
	username = trim_space(POST_PARAMS["username"])
	password = trim_space(POST_PARAMS["password"])
	chkres = check_user_password(ENVIRON["DOCUMENT_ROOT"], username, password)
	if (int(chkres) == 0) {
		cgi::write_http_status(403, "Forbidden")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   403,
				   "Username or password mismatch.",
				   "/login.awk",
				   5))
	} else {
		new_session = create_session_string()
		set_session(ENVIRON["DOCUMENT_ROOT"], username, new_session,
					(get_timestamp() + 604800))
		
		cgi::write_http_status(302, "Found")
		cgi::begin_write_http_header()
		line = sprintf("username=%s; Max-Age=604800; Secure; HttpOnly", username)
		cgi::write_http_header("Set-Cookie", line)
		line = sprintf("session=%s; Max-Age=604800; Secure; HttpOnly", new_session)
		cgi::write_http_header("Set-Cookie", line)
		cgi::write_http_header("Content-Length", "0")
		cgi::write_http_header("Location", "/index.awk")
		cgi::end_write_http_header()
	}
}



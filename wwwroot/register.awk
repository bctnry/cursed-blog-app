#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_user.awk"
@include "../lib/db_session.awk"
@include "../lib/aux.awk"

BEGIN {
	if (cgi::is_get_request()) {
		handle_register_get()
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
		handle_register_post()
	}
}

function handle_register_get(\
	f, line) {
	
	f = ENVIRON["DOCUMENT_ROOT"] "../templates/register.html"
	
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	
	while(getline line < f) { printf("%s\n", line) }
}

function handle_register_post(chkres,
							  #local
							  username, password, new_session,
							  current_timestamp,
							  line, user, user_exist) {
	cgi::parse_query(BODY, POST_PARAMS)
	username = trim_space(POST_PARAMS["username"])
	password = trim_space(POST_PARAMS["password"])
	delete user
	user_exist = get_user(ENVIRON["DOCUMENT_ROOT"], username)
	if (user_exist) {
		cgi::write_http_status(400, "")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template( \
				   ENVIRON["DOCUMENT_ROOT"],
				   400,
				   "User already exists.",
				   "/register.awk",
				   5))
		return
	}
	register_user(ENVIRON["DOCUMENT_ROOT"], username, password, "normal_user")
	cgi::write_http_status(200, "")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	printf("%s", render_redirect_template(			\
			   ENVIRON["DOCUMENT_ROOT"],
			   "Registered",
			   200,
			   "Registered. You should be able to login now.",
			   "/login.awk",
			   5))
}



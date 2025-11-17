#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_user.awk"
@include "../lib/db_session.awk"
@include "../lib/bcrypt_wrapper.awk"
@include "../lib/aux.awk"

BEGIN {
	if (is_get_request()) {
		handle_login_get()
	} else if (is_post_request()) {
		BODY = ""
	} else {
		write_http_status(405, "Method Not Allowed")
	}
}

{
	if (is_post_request()) { BODY = BODY $0 "\n" }
}

END {
	if (is_post_request()) {
		gsub(/\n$/, "", BODY)
		handle_login_post()
	}
}

function handle_login_get(\
	f, line) {
	
	f = ENVIRON["DOCUMENT_ROOT"] "../templates/login.html"
	
	write_http_status(200, "OK")
	begin_write_http_header()
	write_http_header("Content-Type", "text/html")
	end_write_http_header()
	
	while(getline line < f) { printf("%s\n", line) }
}

function handle_login_post(chkres,
						   #local
						   username, password, new_session,
						   current_timestamp,
						   line) {
	parse_query(BODY, POST_PARAMS)
	username = trim_space(POST_PARAMS["username"])
	password = trim_space(POST_PARAMS["password"])
	chkres = check_user_password(ENVIRON["DOCUMENT_ROOT"], username, password)
	if (int(chkres) == 0) {
		write_http_status(403, "Forbidden")
		begin_write_http_header()
		write_http_header("Content-Type", "text/html")
		end_write_http_header()
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
		
		write_http_status(302, "Found")
		begin_write_http_header()
		line = sprintf("username=%s; Max-Age=604800; Secure; HttpOnly", username)
		write_http_header("Set-Cookie", line)
		line = sprintf("session=%s; Max-Age=604800; Secure; HttpOnly", new_session)
		write_http_header("Set-Cookie", line)
		write_http_header("Content-Length", "0")
		write_http_header("Location", "/index.awk")
		end_write_http_header()
	}
}



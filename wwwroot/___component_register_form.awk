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
		handle_component_register_form_get()
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
		handle_component_register_form_post()
	}
}

function handle_component_register_form_get(data) {
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	delete data
	printf("%s", template::render_template_file(\
			   ENVIRON["DOCUMENT_ROOT"] "../templates/register-form.html",
			   data))
}

function handle_component_register_form_post() {
	cgi::parse_query(BODY, POST_PARAMS)
	username = trim_space(POST_PARAMS["username"])
	password = trim_space(POST_PARAMS["password"])
	delete user
	user_exist = get_user(ENVIRON["DOCUMENT_ROOT"], username)
	if (user_exist) {
		cgi::write_http_status(200, "")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		delete data
		data["ErrorMsg"] = "User already exists."
		printf("%s", template::render_template_file(	\
				   ENVIRON["DOCUMENT_ROOT"] "../templates/register-form.html",
				   data))
		return
	}
	register_user(ENVIRON["DOCUMENT_ROOT"], username, password, "normal_user")
	cgi::write_http_status(200, "")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
		delete data
		data["ErrorMsg"] = "Registered. You should be able to login now."
		printf("%s", template::render_template_file(	\
				   ENVIRON["DOCUMENT_ROOT"] "../templates/register-form.html",
				   data))
}


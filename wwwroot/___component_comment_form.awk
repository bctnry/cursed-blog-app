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
		handle_component_comment_form_get()
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
		handle_component_comment_form_post()
	}
}

function handle_component_comment_form_get(data) {
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	cgi::parse_query(BODY, POST_PARAMS)
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	delete data
	data["ArticleID"] = GET_PARAMS["id"]
	printf("%s", template::render_template_file(\
			   ENVIRON["DOCUMENT_ROOT"] "../templates/component-comment-form.html",
			   data))
}

function handle_component_comment_form_post() {
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	cgi::parse_query(BODY, POST_PARAMS)
	new_comment(ENVIRON["DOCUMENT_ROOT"],
				POST_PARAMS["article-id"],
				POST_PARAMS["name"],
				POST_PARAMS["email"],
				POST_PARAMS["website"],
				POST_PARAMS["content"])
	cgi::write_http_status(302, "Found")
	cgi::begin_write_http_header()
	cgi::write_http_header("Location", sprintf("___component_comment_list.awk?id=%s", POST_PARAMS["article-id"]))
	cgi::write_http_header("Content-Length", "0")
	cgi::end_write_http_header()
}


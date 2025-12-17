#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_comment.awk"
@include "../lib/db_session.awk"
@include "../lib/aux.awk"

BEGIN {
	if (cgi::is_get_request()) {
		handle_edit_comment_get()
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
		handle_edit_comment_post()
	}
}

function handle_edit_comment_get() {
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
				   "Please log in first.",
				   "/login.awk",
				   5))
		return
	}
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	get_comment_by_id(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["pid"], GET_PARAMS["cid"], comment)
	
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()

	header()
	printf("<form id=\"edit-comment-form\" action=\"#\" method=\"POST\">")
	printf("  <table>")
	printf("	<tr>")
	printf("	  <td><label for=\"name\">Name: </label></td>")
	printf("	  <td><input class=\"edit-comment-form-input\" name=\"name\" id=\"name\" value=\"%s\" /></td>", comment["Name"])
	printf("	</tr>")
	printf("	<tr>")
	printf("	  <td><label for=\"email\">Email: </label></td>")
	printf("	  <td><input class=\"edit-comment-form-input\" name=\"email\" id=\"email\" value=\"%s\" /></td>", comment["Email"])
	printf("    </tr>")
	printf("	<tr>")
	printf("	  <td><label for=\"website\">Website: </label></td>")
	printf("	  <td><input class=\"edit-comment-form-input\" name=\"website\" id=\"website\" value=\"%s\" /></td>", comment["Website"])
	printf("    </tr>")
	printf("	<tr>")
	printf("	  <td><label for=\"content\">Content: </label></td>")
	printf("	  <td><textarea class=\"edit-article-form-input\" name=\"content\" id=\"content\">")
	printf("%s", comment["Content"])
	printf("</textarea></td>")
	printf("    </tr>")
	printf("    <tr>")
	printf("      <td></td>")
	printf("      <td><input type=\"submit\" value=\"Save\" /></td>")
	printf("      <td></td>")
	printf("    </tr>")
	printf("  </table>")
	printf("</form>")
	printf("<div><a href=\"index.awk\">Back</a></div>")
	footer()
}

function handle_edit_comment_post() {
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
				   "Please log in first.",
				   "/login.awk",
				   5))
		return
	}
	
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	cgi::parse_query(BODY, POST_PARAMS)
	update_comment_by_id(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["pid"], GET_PARAMS["cid"],
						 POST_PARAMS["name"], POST_PARAMS["email"], POST_PARAMS["website"],
						 POST_PARAMS["content"])

	cgi::write_http_status(302, "Found")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::write_http_header("Content-Length", "0")
	cgi::write_http_header("Location", sprintf("article.awk?id=%s", GET_PARAMS["pid"]))
	cgi::end_write_http_header()
}

function header() {
	printf("%s", render_header_template(ENVIRON["DOCUMENT_ROOT"], "Create article"))
}

function footer() {
	printf("%s", render_footer_template(ENVIRON["DOCUMENT_ROOT"]))
}


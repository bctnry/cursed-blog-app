#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_article.awk"
@include "../lib/db_session.awk"
@include "../lib/bcrypt_wrapper.awk"
@include "../lib/aux.awk"

BEGIN {
	if (is_get_request()) {
		handle_edit_get()
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
		handle_edit_post()
	}
}

function handle_edit_get() {
	parse_cookie(COOKIE)
	chkres = check_session(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], COOKIE["session"])
	if (!chkres) {
		write_http_status(403, "Forbidden")
		begin_write_http_header()
		write_http_header("Content-Type", "text/html")
		end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   403,
				   "Please log in first.",
				   "/login.awk",
				   5))
		return
	}
	parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	get_article_by_id(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["id"], article)
	
	write_http_status(200, "OK")
	begin_write_http_header()
	write_http_header("Content-Type", "text/html")
	end_write_http_header()

	header()
	printf("<form id=\"edit-article-form\" action=\"#\" method=\"POST\">")
	printf("  <table>")
	printf("	<tr>")
	printf("	  <td><label for=\"title\">Title: </label></td>")
	printf("	  <td><input class=\"edit-article-form-input\" name=\"title\" id=\"title\" value=\"%s\" /></td>", article["Title"])
	printf("	</tr>")
	printf("	<tr>")
	printf("	  <td><label for=\"content\">Content: </label></td>")
	printf("	  <td><textarea class=\"edit-article-form-input\" name=\"content\" id=\"content\">")
	printf("%s", article["Content"])
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

function handle_edit_post() {
	parse_cookie(COOKIE)
	chkres = check_session(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], COOKIE["session"])
	if (!chkres) {
		write_http_status(403, "Forbidden")
		begin_write_http_header()
		write_http_header("Content-Type", "text/html")
		end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   403,
				   "Please log in first.",
				   "/login.awk",
				   5))
		return
	}
	
	parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	parse_query(BODY, POST_PARAMS)
	title = trim_space(POST_PARAMS["title"])
	content = trim_space(POST_PARAMS["content"])

	update_article(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["id"], title, content)

	write_http_status(302, "Found")
	begin_write_http_header()
	write_http_header("Content-Type", "text/html")
	write_http_header("Content-Length", "0")
	write_http_header("Location", sprintf("article.awk?id=%s", GET_PARAMS["id"]))
	end_write_http_header()
}

function header() {
	printf("%s", render_header_template(ENVIRON["DOCUMENT_ROOT"], "Create article"))
}

function footer() {
	printf("%s", render_footer_template(ENVIRON["DOCUMENT_ROOT"]))
}


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
		handle_component_create_article_form_get()
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
		handle_create_post()
	}
}

function handle_component_create_article_form_get() {
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	printf("<form id=\"create-article-form\" hx-post=\"___component_create_article_form.awk\" hx-swap=\"transition:true\">")
	printf("  <table>")
	printf("	<tr>")
	printf("	  <td><label for=\"title\">Title: </label></td>")
	printf("	  <td><input class=\"create-article-form-input\" name=\"title\" id=\"title\" /></td>")
	printf("	</tr>")
	printf("	<tr>")
	printf("	  <td><label for=\"content\">Content: </label></td>")
	printf("	  <td><textarea class=\"create-article-form-input\" name=\"content\" id=\"content\"></textarea></td>")
	printf("    </tr>")
	printf("    <tr>")
	printf("      <td></td>")
	printf("      <td><input type=\"submit\" value=\"Publish\" /></td>")
	printf("      <td></td>")
	printf("    </tr>")
	printf("  </table>")
	printf("</form>")
	printf("<div><a hx-get=\"___component_article_list.awk\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\">Back</a></div>")
}

function handle_create_post() {
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

	cgi::parse_query(BODY, POST_PARAMS)
	title = trim_space(POST_PARAMS["title"])
	content = trim_space(POST_PARAMS["content"])

	create_article(ENVIRON["DOCUMENT_ROOT"], title, content)

	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	printf("<div hx-get=\"___component_article_list.awk\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\" hx-trigger=\"load\"></div>")
}


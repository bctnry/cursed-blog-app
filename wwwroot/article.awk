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
		handle_article_get()
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
		handle_article_post()
	}
}

function handle_article_get() {
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)

	cgi::parse_cookie(COOKIE)
	chkres = check_session(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], COOKIE["session"])

	getuser_res = get_user(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], user)

	get_article_by_id(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["id"], article)
	get_all_comments_of_article(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["id"], comment_list)

	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	
	header(article["Title"])
	printf("<div id=\"single-article-main\">")
	printf("  <h1 class=\"single-article-title\"><a href=\"%s\">%s</a></h1>", ENVIRON["REQUEST_URI"], article["Title"])
	printf("  <div class=\"single-article-author\">by %s</di>", article["Author"])
	printf("  <div class=\"single-article-datetime\">%s", article["Datetime"])
	if (chkres && getuser_res && (user["Username"] == COOKIE["username"] || user["Role"] == "admin")) {
		printf(" <a href=\"edit.awk?id=%s\">edit</a> ", GET_PARAMS["id"])
	}
	printf("</div>")
	printf("  <div class=\"single-article-body\">%s</div>", article["Content"])
	printf("</div>")
	printf("<div class=\"bottom-nav\"><a href=\"index.awk\">Back</a></div>")
	
	# comments.
	printf("<div class=\"comment-list\">")
	for (k in comment_list) {
		reclib::parse_record(comment_list[k], r)
		display_comment(r["ID"], comment_list[k], chkres)
	}
	printf("</div>")

	display_comment_form()
	
	footer()
	
}

function display_comment(comment_id, comment, allow_edit,
						 #local
						 cmd, line, tempfile, edit_line,
						 res) {
	tempfile = ENVIRON["DOCUMENT_ROOT"] "../.temp"
	if (allow_edit) {
		edit_line = sprintf("<a class=\"comment-edit-link\" href=\"edit-comment.awk?pid=%s&cid=%d\">edit</a>",
							GET_PARAMS["id"], comment_id)
	} else {
		edit_line = ""
	}
	printf(sprintf("ShowEditLink: %s\n%s", edit_line, comment)) > tempfile
	close(tempfile)
	cmd = "recfmt -f " ENVIRON["DOCUMENT_ROOT"] "../templates/comment.html <" tempfile
	res = ""
	while (cmd | getline line) { res = res line "\n" }
	close(cmd)
	print (res)
}


function display_comment_form(line, template_file) {
	template_file = ENVIRON["DOCUMENT_ROOT"] "../templates/comment_form.html"
	while ((getline line < template_file) > 0) { printf("%s\n", line) }
}

function _report_no_permission() {
	cgi::write_http_status(403, "Forbidden")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	printf("%s", render_error_template(\
			   ENVIRON["DOCUMENT_ROOT"],
			   403,
			   "Invalid credentials.",
			   "/index.awk",
			   3))
}

function handle_article_post() {
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	cgi::parse_query(BODY, POST_PARAMS)
	new_comment(ENVIRON["DOCUMENT_ROOT"],
				GET_PARAMS["id"],
				POST_PARAMS["name"],
				POST_PARAMS["email"],
				POST_PARAMS["website"],
				POST_PARAMS["content"])
	cgi::write_http_status(302, "Found")
	cgi::begin_write_http_header()
	cgi::write_http_header("Location", ENVIRON["REQUEST_URI"])
	cgi::write_http_header("Content-Length", "0")
	cgi::end_write_http_header()
}


function header(title) {
	printf("%s", render_header_template(ENVIRON["DOCUMENT_ROOT"], title))
}

function footer() {
	printf("%s", render_footer_template(ENVIRON["DOCUMENT_ROOT"]))
}



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
		handle_component_article_get()
	} else {
		cgi::write_http_status(405, "Method Not Allowed")
	}
}

function handle_component_article_get() {
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	chk = get_article_by_id(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["id"], article)
	if (!chk) {
		cgi::write_http_status(404, "Not Found")
		return
	}
	
	cgi::parse_cookie(COOKIE)
	getuser_res = get_user(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], user)
	
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()

	printf("<div id=\"main\">")
	printf("<div id=\"single-article-main\">")
	printf("  <h1 class=\"single-article-title\">%s</h1>", article["Title"])
	printf("  <div class=\"single-article-author\">by %s</di>", article["Author"])
	printf("  <div class=\"single-article-datetime\">%s", article["Datetime"])
	if (chkres && getuser_res && (user["Username"] == COOKIE["username"] || user["Role"] == "admin")) {
		printf(" <a href=\"edit.awk?id=%s\">edit</a> ", GET_PARAMS["id"])
	}
	printf("  </div>")
	printf("  <div class=\"single-article-body\">%s</div>", article["Content"])
	printf("</div>")
	printf("<div class=\"bottom-nav\"><a hx-get=\"___component_article_list.awk\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\">Back</a></div>")
    printf(sprintf("<div id=\"comment-list\" hx-get=\"___component_comment_list.awk?id=%s\" hx-target=\"#comment-list\" hx-swap=\"innerHTML transition:true\" hx-trigger=\"load\"></div>", GET_PARAMS["id"]))
	printf(sprintf("<div id=\"comment-form\" hx-get=\"___component_comment_form.awk?id=%s\" hx-swap=\"innerHTML transition:true\" hx-target=\"#comment-form\" hx-trigger=\"load\"></div>", GET_PARAMS["id"]))
    printf("</div>")
		   
}



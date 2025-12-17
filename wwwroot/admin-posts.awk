#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/db_article.awk"
@include "../lib/db_user.awk"
@include "../lib/db_session.awk"
@include "../lib/aux.awk"
@include "../lib/reclib.awk"

BEGIN {
	if (cgi::is_get_request()) {
		cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
		handle_admin_posts_get()
	} else if (cgi::is_post_request()) {
		BODY = ""
	} else {
		cgi::write_status(405, "Method Not Allowed")
	}
}

{
	if (cgi::is_get_request()) { BODY = BODY $0 "\n" }
}

END {
	if (cgi::is_post_request()) {
		gsub(/\n$/, "", BODY)
		handle_admin_posts_post()
	}
}

function handle_admin_posts_post() {
	# intentionally left blank - we're not using POST requests here.
}

function handle_admin_posts_get() {
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
				   "Pleasee log in first.",
				   "/login.awk",
				   5))
		return
	}
	if (!get_user(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], user)) {
		cgi::write_http_status(403, "Forbidden")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   403,
				   "Invalid credentials.",
				   "/login.awk",
				   5))
		return
	}
	if (user["Role"] != "admin") {
		cgi::write_http_status(403, "Forbidden")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   403,
				   "Invalid credentials.",
				   "/login.awk",
				   5))
		return
	}
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	
	if (GET_PARAMS["action"] == "delete") {
		delete_article(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["id"])
		cgi::write_http_status(200, "OK")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_redirect_template(\
				   ENVIRON["DOCUMENT_ROOT"],
				   "Article deleted",
				   200,
				   "Article deleted.",
				   "/admin-posts.awk",
				   5))
		return
	}

	total_num = count_article(ENVIRON["DOCUMENT_ROOT"])
	if (GET_PARAMS["p"] == "") { page_num = 0 } else { page_num = int(GET_PARAMS["p"]) }
	if (GET_PARAMS["s"] == "") { page_size = 30 } else { page_size = int(GET_PARAMS["s"]) }
	target_start = total_num - (page_num + 1) * page_size
	page_count = int(total_num / page_size)
	if (page_size * page_count < total_num) { page_count++ }

	get_all_articles(ENVIRON["DOCUMENT_ROOT"], articles, target_start, page_size)

	if (length(articles) <= 0) {
		printf("<p>there's no article yet.</p>")
	}
	reverse(articles, articles_2)

	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	
	header("Admin Panel")
	printf("<div id=\"main\">")
	
	printf("<div class=\"top-nav\">")
	printf("<div>back to <a href=\"admin.awk\">admin panel</a> / <a href=\"index.awk\">front page</a></div>")
	if (page_num < page_count-1) {
		printf("<a href=\"admin-posts.awk?p=%d&s=%d\">&lt;&lt;</a>", page_num+1, page_size)
	}
	
	if (page_num > 0) {
		printf("<a href=\"admin-posts.awk?p=%d&s=%d\">&gt;&gt;</a>", page_num-1, page_size)
	}
	printf("</div>")
	
	for (i in articles_2) {
		reclib::parse_record(articles_2[i], article)
		render_article_item(article)
	}
	printf("</div>")
	footer()
}

function render_article_item(article) {
	printf("<div class=\"article\">")
	printf("<span class=\"article-id\">#%s</span>", article["ID"])
	printf(" <span class=\"article-title\">%s</span>", article["Title"])
	printf(" <a href=\"article.awk?id=%s\">read</a>", article["ID"])
	printf("<br />")
	printf("<span class=\"article-datetime\">%s</span>", article["Datetime"])
	printf(" <a href=\"./edit.awk?id=%s\">edit</a>", article["ID"])
	printf(" <a href=\"./admin-posts.awk?id=%s&action=delete\">delete</a>", article["ID"])
	printf("</div>")
}

function header(title) {
	printf("%s", render_header_template(ENVIRON["DOCUMENT_ROOT"], title))
}

function footer() {
	printf("%s", render_footer_template(ENVIRON["DOCUMENT_ROOT"]))
}



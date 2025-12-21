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
		handle_component_article_list_get()
	} else {
		cgi::write_http_status(405, "Method Not Allowed")
	}
}

function handle_component_article_list_get() {
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	
	total_num = count_article(ENVIRON["DOCUMENT_ROOT"])
	
	if (GET_PARAMS["p"] == "") { page_num = 0 } else { page_num = int(GET_PARAMS["p"]) }
	if (GET_PARAMS["s"] == "") { page_size = 5 } else { page_size = int(GET_PARAMS["s"]) }
	target_start = total_num - (page_num + 1) * page_size
	page_count = int(total_num / page_size)
	if (page_size * page_count < total_num) { page_count++ }

	get_all_articles(ENVIRON["DOCUMENT_ROOT"], articles, target_start, page_size)

	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()

	printf("<div id=\"main\">")
	printf("<div id=\"article-list\">")
	
	printf("<div class=\"top-nav\">")
	if (page_num < page_count-1) {
		printf("<a hx-get=\"___component_article_list.awk?p=%d&s=%d\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\" >&lt;&lt;</a>", page_num+1, page_size)
	}
	
	if (page_num > 0) {
		printf("<a hx-get=\"___component_article_list.awk?p=%d&s=%d\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\">&gt;&gt;</a>", page_num-1, page_size)
	}
	printf("</div>")
	
	if (length(articles) <= 0) {
		printf("<p>there's no article yet. ")
		if (chkses_res) {
			printf("<a href=\"create.awk\">write one</a>.")
		}
		printf("</p>")
	} else {
		reverse(articles, articles_2)
		for (i in articles_2) {
			reclib::parse_record(articles_2[i], article)
			print render_article(article)
		}
	}

	printf("</div>")
	
	printf("</div>")
}

function render_article(a,
						#local
						i) {
	printf("<div class=\"article\">")
    printf("  <div class=\"article-title\"><a hx-get=\"___component_article.awk?id=%d\" hx-target=\"#main\" hx-swap=\"innerHTML transition:true\">#%d %s</a></div>",
		   a["ID"], a["ID"], a["Title"])
	printf("  <div class=\"article-datetime\">%s</div>", a["Datetime"])
	printf("</div>")
}


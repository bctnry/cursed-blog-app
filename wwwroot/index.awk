#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_article.awk"
@include "../lib/db_session.awk"
@include "../lib/db_user.awk"
@include "../lib/aux.awk"

BEGIN {
	if (ENVIRON["REQUEST_METHOD"] == "GET") {
		cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
		handle_get_all_articles()
	} else if (ENVIRON["REQUEST_METHOD"] == "POST") {
		BODY = ""
	} else {
		cgi::write_status(405, "Method Not Allowed")
	}
}

{
	if (ENVIRON["REQUEST_METHOD"] == "POST") {
		BODY = BODY $0 "\n"
	}
}

END {
	if (ENVIRON["REQUEST_METHOD"] == "POST") {
		gsub(/\n$/, "", BODY)
		cgi::parse_query(BODY, POST_PARAMS)
	}
}

function handle_get_all_articles(\
	k, i,
	chkses_res) {
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)

	# recutils seems to not support reverse sort order so we have to do this...
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

	header()

	printf("<div id=\"meta\" hx-get=\"___component_nav_bar.awk\" hx-target=\"#meta\" hx-trigger=\"load\"></div>")
	printf("<div id=\"main\" hx-get=\"___component_article_list.awk\" hx-target=\"#main\" hx-trigger=\"load\"></div>")
	
	footer()
}

function logged_in() {
    if (length(COOKIE["username"]) <= 0) { return 0; }
    if (length(COOKIE["session"]) <= 0) { return 0; }
    
}

function render_article(a,
						#local
						i) {
	printf("<div class=\"article\">")
    printf("  <div class=\"article-title\"><a href=\"article.awk?id=%d\">#%d %s</a></div>",
		   a["ID"], a["ID"], a["Title"])
	printf("  <div class=\"article-datetime\">%s</div>", a["Datetime"])
	printf("</div>")
}


function header() {
	printf("%s", render_header_template(ENVIRON["DOCUMENT_ROOT"], "Lighttpd + Awk + Recfiles cursed blog app demo"))
}

function footer() {
	printf("%s", render_footer_template(ENVIRON["DOCUMENT_ROOT"]))
}

		

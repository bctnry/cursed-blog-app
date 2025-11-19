#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/reclib.awk"
@include "../lib/db_article.awk"
@include "../lib/db_session.awk"
@include "../lib/bcrypt_wrapper.awk"
@include "../lib/aux.awk"

BEGIN {
	if (ENVIRON["REQUEST_METHOD"] == "GET") {
		parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
		handle_get_all_articles()
	} else if (ENVIRON["REQUEST_METHOD"] == "POST") {
		BODY = ""
	} else {
		write_status(405, "Method Not Allowed")
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
		parse_query(BODY, POST_PARAMS)
	}
}

function handle_get_all_articles(\
	k, i,
	chkses_res) {
	parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)

	# recutils seems to not support reverse sort order so we have to do this...
	total_num = count_article(ENVIRON["DOCUMENT_ROOT"])
	
	if (GET_PARAMS["p"] == "") { page_num = 0 } else { page_num = int(GET_PARAMS["p"]) }
	if (GET_PARAMS["s"] == "") { page_size = 5 } else { page_size = int(GET_PARAMS["s"]) }
	target_start = total_num - (page_num + 1) * page_size
	page_count = int(total_num / page_size)
	if (page_size * page_count < total_num) { page_count++ }

	get_all_articles(ENVIRON["DOCUMENT_ROOT"], articles, target_start, page_size)

	write_http_status(200, "OK")
	
	begin_write_http_header()
	write_http_header("Content-Type", "text/html")
	end_write_http_header()

	header()
	parse_cookie(COOKIE)
	chkses_res = check_session(ENVIRON["DOCUMENT_ROOT"], COOKIE["username"], COOKIE["session"])
	if (chkses_res) {
		printf("<div class=\"meta\">logged in as %s. <a href=\"logout.awk\">logout</a> ",
			   COOKIE["username"])
		printf("<a href=\"create.awk\">new post</a>")
		printf("</div>")
	} else {
		printf("<div class=\"meta\"><a href=\"login.awk\">login</a></div>")
	}

	printf("<div id=\"main\">")
	printf("<div id=\"article-list\">")
	
	printf("<div class=\"top-nav\">")
	if (page_num < page_count-1) {
		printf("<a hx-target=\"#article-list\" hx-get=\"html/article-list.awk?p=%d&s=%d\">&lt;&lt;</a>", page_num+1, page_size)
	}
	
	if (page_num > 0) {
		printf("<a hx-target=\"#article-list\" hx-get=\"html/article-list.awk?p=%d&s=%d\">&gt;&gt;</a>", page_num-1, page_size)
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
			rec_parse_record(articles_2[i], article)
			print render_article(article)
		}
	}

	printf("</div>")
	
	printf("</div>")
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

		

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
		handle_component_comment_list_get()
	} else {
		cgi::write_http_status(405, "Method Not Allowed")
	}
}

function handle_component_comment_list_get() {
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

	get_all_comments_of_article(ENVIRON["DOCUMENT_ROOT"], GET_PARAMS["id"], comment_list)
	printf("<div class=\"comment-list\">")
	if (length(comment_list) <= 0) {
		printf("There is no comment yet.")
	} else {
		for (k in comment_list) {
			reclib::parse_record(comment_list[k], r)
			display_comment(r["ID"], r, chkres)
		}
	}
	printf("</div>")
}

function display_comment(comment_id, comment, allow_edit,
						 #local
						 data) {
	delete data
	data["ID"] = comment_id
	data["Name"] = comment["Name"]
	data["Datetime"] = comment["Datetime"]
	data["Email"] = comment["Email"]
	data["Website"] = comment["Website"]
	data["Content"] = comment["Content"]
	data["ShowEditLink"] = ""
	if (allow_edit) {
		data["ShowEditLink"] = sprintf("<a class=\"comment-edit-link\" href=\"edit-comment.awk?pid=%s&cid=%d\">edit</a>",
							GET_PARAMS["id"], comment_id)
	}
	printf("%s\n", template::render_template_file(\
			   ENVIRON["DOCUMENT_ROOT"] "../templates/comment.html",
			   data))
}




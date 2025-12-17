#!/usr/bin/env -S awk -f

@include "../lib/cgilib.awk"
@include "../lib/db_user.awk"
@include "../lib/db_session.awk"
@include "../lib/aux.awk"
@include "../lib/reclib.awk"

BEGIN {
	if (cgi::is_get_request()) {
		cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
		handle_admin_user_get()
	} else if (cgi::is_post_request()) {
		BODY = ""
	} else {
		cgi::write_status(405, "Method Not Allowed")
	}
}

{
	if (cgi::is_post_request()) { BODY = BODY $0 "\n" }
}

END {
	if (cgi::is_post_request()) {
		gsub(/\n$/, "", BODY)
		handle_admin_user_post()
	}
}

function handle_admin_user_get(\
	chkres, user, total_num, page_count, page_size, page_num,
	users, users_2, user_item) {
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
		handle_user_delete_get(GET_PARAMS["username"])
		return
	} else if (GET_PARAMS["action"] == "edit") {
		handle_user_edit_get(GET_PARAMS["username"])
		return
	} else if (GET_PARAMS["action"] == "new") {
		handle_user_new_get(GET_PARAMS["username"])
		return
	}

	
	total_num = count_user(ENVIRON["DOCUMENT_ROOT"])
	if (GET_PARAMS["p"] == "") { page_num = 0 } else { page_num = int(GET_PARAMS["p"]) }
	if (GET_PARAMS["s"] == "") { page_size = 30 } else { page_size = int(GET_PARAMS["s"]) }
	target_start = total_num - (page_num + 1) * page_size
	page_count = int(total_num / page_size)
	if (page_size * page_count < total_num) { page_count++ }
	get_all_users(ENVIRON["DOCUMENT_ROOT"], users, target_start, page_size)
	if (length(users) <= 0) {
		printf("<p>there's no user yet. (how in the world did you manage to get here?)</p>")
	}
	reverse(users, users_2)
	
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	header("Admin Panel")
	
	printf("<div id=\"main\">")
	
	printf("<div class=\"top-nav\">")
	printf("<div>back to <a href=\"admin.awk\">admin panel</a> / <a href=\"index.awk\">front page</a></div>")
	if (page_num < page_count-1) {
		printf("<a href=\"admin-user.awk?p=%d&s=%d\">&lt;&lt;</a>", page_num+1, page_size)
	}
	
	if (page_num > 0) {
		printf("<a href=\"admin-user.awk?p=%d&s=%d\">&gt;&gt;</a>", page_num-1, page_size)
	}
	printf("</div>")

	printf("<div style=\"margin-top:2rem\">")
	printf("<div><a href=\"./admin-user.awk?action=new\">new user</a></div>")
	for (i in users_2) {
		reclib::parse_record(users_2[i], user_item)
		render_user_item(user_item)
	}
    printf("</div>")

	printf("</div>")

	footer()
}

function render_user_item(user_item) {
	printf("<div class=\"user\">")
	printf("<div>User (%s) <span class=\"user-name\">%s</span> <a href=\"admin-user.awk?username=%s&action=edit\">edit</a> <a href=\"admin-user.awk?username=%s&action=delete\">delete</a></div>", user_item["Role"], user_item["Username"], user_item["Username"], user_item["Username"])
	printf("</div>")
}

function handle_user_new_get(\
	data) {
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	header("New user")
	delete data
	printf("%s", template::render_template_file(				\
			   ENVIRON["DOCUMENT_ROOT"] "../templates/admin-user-new.html",
			   data))
	footer()
}

function handle_user_delete_get(username) {
	delete_user(ENVIRON["DOCUMENT_ROOT"], username)
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	printf("%s", render_redirect_template(			\
			   ENVIRON["DOCUMENT_ROOT"],
			   "User deleted",
			   200,
			   "User deleted.",
			   "/admin-user.awk",
			   5))
	return
}

function handle_user_edit_get(username,
							  #local
							  r, uobj, _roleselect, _selected) {
	r = get_user(ENVIRON["DOCUMENT_ROOT"], username, uobj)
	if (!r) {
		cgi::write_http_status(404, "Not Found")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   404,
				   "User not found.",
				   "/admin-user.awk",
				   5))
		return
	}
	cgi::write_http_status(200, "OK")
	cgi::begin_write_http_header()
	cgi::write_http_header("Content-Type", "text/html")
	cgi::end_write_http_header()
	header(sprintf("Editing user %s", username))

	_selected = ""
	if (uobj["Role"] == "admin") { _selected = "selected" }
	_roleselect = sprintf("<option value=\"admin\" %s>admin</option>", _selected)
	_selected = ""
	if (uobj["Role"] == "normal_user") { _selected = "selected" }
	_roleselect = _roleselect sprintf("<option value=\"normal_user\" %s>normal_user</option>", _selected)
	uobj["_RoleSelect"] = _roleselect
	
	printf("%s", template::render_template_file(\
			   ENVIRON["DOCUMENT_ROOT"] "../templates/admin-user-edit.html",
			   uobj))
	footer()
}


function header(title) {
	printf("%s", render_header_template(ENVIRON["DOCUMENT_ROOT"], title))
}

function footer() {
	printf("%s", render_footer_template(ENVIRON["DOCUMENT_ROOT"]))
}


function handle_admin_user_post(\
	chkres, user, username) {
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
				   "No privilege.",
				   "/index.awk",
				   5))
		return
	}
	cgi::parse_query(ENVIRON["QUERY_STRING"], GET_PARAMS)
	cgi::parse_query(BODY, POST_PARAMS)
	username = POST_PARAMS["username"]
	if (POST_PARAMS["action"] == "update-role") {
		new_role = POST_PARAMS["role"]
		update_user_role(ENVIRON["DOCUMENT_ROOT"], username, new_role)
		printf("%s", render_redirect_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   "User role updated",
				   200,
				   "User role updated.",
				   sprintf("/admin-user.awk?username=%s&action=edit", username),
				   5))
	} else if (POST_PARAMS["action"] == "update-password") {
		new_password = POST_PARAMS["password"]
		update_user_password(ENVIRON["DOCUMENT_ROOT"], username, new_password)
		printf("%s", render_redirect_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   "User password updated",
				   200,
				   "User password updated.",
				   sprintf("/admin-user.awk?username=%s&action=edit", username),
				   5))
	} else if (POST_PARAMS["action"] == "new-user") {
		new_username = POST_PARAMS["username"]
		new_password = POST_PARAMS["password"]
		register_user(ENVIRON["DOCUMENT_ROOT"], new_username, new_password, "normal_user")
		printf("%s", render_redirect_template(		\
			   ENVIRON["DOCUMENT_ROOT"],
			   "User created",
			   200,
			   "User created.",
			   "/admin-user.awk",
			   5))
	} else {
		cgi::write_http_status(400, "Invalid Request")
		cgi::begin_write_http_header()
		cgi::write_http_header("Content-Type", "text/html")
		cgi::end_write_http_header()
		printf("%s", render_error_template(		\
				   ENVIRON["DOCUMENT_ROOT"],
				   400,
				   sprintf("Invalid request: %s, %s", username, POST_PARAMS["action"]),
				   "/admin-user.awk",
				   5))
		return
	}
}

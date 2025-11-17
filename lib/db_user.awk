function get_user(doc_root, name, out,
				  #local
				  str, line,
				  cmd, users_file) {
	users_file = doc_root "../db/users.rec"
	cmd = "recsel -t User -e \"Username = '" name "'\" " users_file
	str = ""
	while (cmd | getline line) { str = str line "\n" }
	delete out
	rec_parse_record(str, out)
	gsub(/^[[:space:]]+/, "", out["Username"])
	gsub(/[[:space:]]+$/, "", out["Username"])
	gsub(/^[[:space:]]+/, "", out["PasswordHash"])
	gsub(/[[:space:]]+$/, "", out["PasswordHash"])
}

function check_user_password(doc_root, name, password,
							 #local
							 user) {
	get_user(doc_root, name, user)
	return compare_password(doc_root, password, user["PasswordHash"])
}


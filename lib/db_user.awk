@load "../gawk_bcrypt"

function count_user(doc_root,
					#local
					cmd, line, users_file) {
	users_file = doc_root "../db/users.rec"
	cmd = "recsel -t User -c " users_file
	cmd | getline line
	close(cmd)
	return int(line)
}

function get_user(doc_root, name, out,
				  #local
				  str, line,
				  cmd, users_file) {
	users_file = doc_root "../db/users.rec"
	cmd = "recsel -t User -e \"Username = '" name "'\" " users_file
	str = ""
	while (cmd | getline line) { str = str line "\n" }
	if (!str) { return 0 }
	reclib::parse_record(str, out)
	gsub(/^[[:space:]]+/, "", out["Username"])
	gsub(/[[:space:]]+$/, "", out["Username"])
	gsub(/^[[:space:]]+/, "", out["Role"])
	gsub(/[[:space:]]+$/, "", out["Role"])
	gsub(/^[[:space:]]+/, "", out["PasswordHash"])
	gsub(/[[:space:]]+$/, "", out["PasswordHash"])
	return 1
}

function get_user_raw(doc_root, name,
				  #local
				  str, line,
				  cmd, users_file) {
	users_file = doc_root "../db/users.rec"
	cmd = "recsel -t User -e \"Username = '" name "'\" " users_file
	str = ""
	while (cmd | getline line) { str = str line "\n" }
	if (!str) { return 0 }
	return str
}
function get_all_users(doc_root, out,
					   #optional
					   start, page_size,
					   #local
					   end, cmd, f) {
	f = doc_root "../db/users.rec"
	cmd = "recsel -t User "
	# `recsel -n` ranges are inclusive...
	if (start != "" && page_size == "") {
		page_size = 30
		end = start + page_size - 1
		if (int(start) < 0) { start = 0 }
		if (int(end) < 0) { end = 0 }
		# page_size is 30 by default.
		cmd = cmd sprintf(" -n %d-%d", int(start), int(end))
	} else if (start != "" && page_size != "") {
		end = start + page_size - 1
		if (int(start) < 0) { start = 0 }
		if (int(end) < 0) { end = 0 }
		cmd = cmd sprintf(" -n %d-%d", int(start), int(end))
	}
	cmd = cmd " " f
	delete out
	res = ""
	while (cmd | getline line) {
		if (length(line) <= 0) {
			out[length(out)+1] = res
			res = ""
		} else {
			res = res line "\n"
		}
	}
	if (length(res) > 0) {
		out[length(out)+1] = res
	}
	close(cmd)
}

function register_user(doc_root, name, password, role,
					   #local
					   users_file, hashed_password) {
	users_file = doc_root "../db/users.rec"
	hashed_password = bcrypt::hash_with_salt(password, 10)
	gsub(/\$/, "\\$", hashed_password)
	cmd = "recins -t User "
	cmd = cmd " -f Username -v \"" name "\" "
	cmd = cmd " -f Role -v \"" role "\" "
	cmd = cmd " -f PasswordHash -v \"" hashed_password "\" "
	cmd = cmd " " users_file
	cmd = cmd " --verbose"
	cmd = cmd " >/dev/null"
	system(cmd)
}

function check_user_password(doc_root, name, password,
							 #local
							 user) {
	get_user(doc_root, name, user)
	return bcrypt::check_hash(password, user["PasswordHash"])
}

function update_user_role(doc_root, username, role,
						  #local
						  users_file, cmd) {
	users_file = doc_root "../db/users.rec"
	cmd = sprintf("recset -t User -e \"Username = \\\"%s\\\"\"", username)
	cmd = cmd sprintf(" -f Role -s \"%s\" ", role)
	cmd = cmd " " users_file
	cmd = cmd " >/dev/null"
	system(cmd)
	close(cmd)
}

function update_user_password(doc_root, username, password,
							  #local
							  hash, users_file, cmd) {
	users_file = doc_root "../db/users.rec"
	cmd = sprintf("recset -t User -e \"Username = \\\"%s\\\"\"", username)
	hash = bcrypt::hash_with_salt(password, 10)
	gsub(/\$/, "\\$", hash)
	cmd = cmd sprintf(" -f PasswordHash -s \"%s\" ", hash)
	cmd = cmd " " users_file
	cmd = cmd " >/dev/null"
	system(cmd)
	close(cmd)
}

function delete_user(doc_root, username,
					 #local
					 cmd, f) {
	f = doc_root "../db/users.rec"
	cmd = sprintf("recdel -t User -e \"Username = '%s'\"", username)
	cmd = cmd " " f " >/dev/null"
	system(cmd)
	print(cmd)
	close(cmd)
	f = doc_root sprintf("../db/session/%s", username)
	# NOTE: even gawk does not have a built-in "delete file" function.
	cmd = "rm " f
	system(cmd)
	close(cmd)
}


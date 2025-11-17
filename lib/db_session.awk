function create_session_string() {
	return random_string("abcdefghijklmnopqrstuvwxyz0123456789", 16)
}

function set_session(doc_root, username, session, expire,
					 #local
					 timestamp, cmd,
					 session_dir, target_file) {
	session_dir = doc_root "../db/session"
	target_file = session_dir "/" username
	printf("%s\n%d\n", session, expire) > target_file
	close(target_file)
}

function invalidate_session(doc_root, username,
							#local
							target_file) {
	target_file = doc_root "../db/session/username"
	printf("%s\n0\n", "") > target_file
}

function check_session(doc_root, username, session,
					   #local
					   timestamp, stored_timestamp, stored_session,
					   session_dir, target_file) {
	if (length(session) <= 0) { return 0 }
	target_file = doc_root "../db/session/" username
	getline stored_session < target_file
	getline stored_timestamp < target_file
	close(target_file)
	if (get_timestamp() >= int(stored_timestamp)) {
		return 0
	}
	if (session != stored_session) {
		return 0
	}
	return 1
}


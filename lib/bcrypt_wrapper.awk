

function hash_password(doc_root, password,
					   #local
					   r, cmd) {
	cmd = doc_root "../helper/bcrypt/bcrypt -s " password
	cmd | getline r
	close(cmd)
	return r
}

function compare_password(doc_root, password, hash,
						  #local
						  h, r, cmd) {
	h = hash
	gsub(/\$/, "\\$", h)
	cmd = doc_root "../helper/bcrypt/bcrypt -p " password " \"" h "\""
	cmd | getline r
	close(cmd)
	return int(r)
}
						  


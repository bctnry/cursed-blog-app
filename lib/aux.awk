function trim_space(out, v) {
	v = out
	gsub(/^[[:space:]]+/, "", v)
	gsub(/[[:space:]]+$/, "", v)
	return v
}

function render_error_template(doc_root, status, msg, target, redirect_time_s,
							   #local
							   cfg, res, line,
							   cmd, template_file) {
	template_file = doc_root "../templates/error_msg.html"
	cmd = "recfmt -f " template_file
	cfg = sprintf("ErrorStatus: %d\nErrorMessage: %s\nTarget: %s\nRefreshTime: %d\n",
				  status, msg, target, redirect_time_s)
	res = ""
	printf("%s", cfg) | cmd
	while (cmd | getline line) { res = res line "\n" }
	close(cmd)
	return res
}

function render_header_template(doc_root, title,
								#local
								cfg, res, line,
								cmd, template_file) {
	template_file = doc_root "../templates/header.html"
	cmd = "recfmt -f " template_file
	cfg = sprintf("Title: %s\n", title)
    res = ""
	printf("%s", cfg) |& cmd
	close(cmd, "to")
	while (cmd |& getline line) { res = res line "\n" }
	close(cmd)
	return res
}

function render_footer_template(doc_root,
								#local
								res, line,
								cmd, template_file) {
	template_file = doc_root "../templates/footer.html"
    res = ""
	while (getline line < template_file) { res = res line "\n" }
	close(template_file)
	return res
}

function random_string(cset, n,
					   #local
					   i, idx, res) {
	res = ""
	for (i = 0; i < n; i++) {
		idx = int(length(cset) * rand()) + 1
		res = res substr(cset, idx, 1)
	}
	return res
}

function get_timestamp(cmd, timestamp) {
	cmd = "date +%s"
	cmd | getline timestamp
	close(cmd)
	return int(timestamp)
}

function sha1sum(file,
				 #local
				 matchres,
				 res, res2, cmd, cmd2, line) {
	res = ""
	cmd = "cat " file
	while (cmd | getline line) { res = res line "\n" }
	close(cmd)
	cmd2 = "sha1sum"
	res2 = ""
	while (cmd2 | getline line) { res2 = res2 line "\n" }
	match(res2, /([0-9a-fA-F]+).*/, matchres)
	return matchres[1]
}

function reverse(in_array, out_array,
				 #local
				 i, n) {
	delete out_array
	n = length(in_array)
	for (i = 1; i <= n; i++) {
		out_array[n+1-i] = in_array[i]
	}
}


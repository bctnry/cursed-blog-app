@include "../lib/template.awk"

function trim_space(out, v) {
	v = out
	gsub(/^[[:space:]]+/, "", v)
	gsub(/[[:space:]]+$/, "", v)
	return v
}

function render_redirect_template(doc_root,
								  title, status, msg, target, redirect_time_s,
								  #local
								  tf, data) {
	tf = doc_root "../templates/redirect.html"
	delete data
	data["Title"] = title
	data["Status"] = status
	data["Message"] = msg
	data["Target"] = target
	data["RefreshTime"] = redirect_time_s
	return template::render_template_file(tf, data)
}

function render_error_template(doc_root, status, msg, target, redirect_time_s,
							   #local
							   tf, data) {
	return render_redirect_template(\
		doc_root, sprintf("Error %d", status),
		status, msg, target, redirect_time_s)
}

function render_header_template(doc_root, title,
								#local
							    data, tf) {
	tf = doc_root "../templates/header.html"
	delete data
	data["Title"] = title
	return template::render_template_file(tf, data)
}

function render_footer_template(doc_root,
								#local
								tf, data) {
	tf = doc_root "../templates/footer.html"
	delete data
	return template::render_template_file(tf, data)
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



function count_article(doc_root,
					   #local
					   cmd, line, articles_file) {
	articles_file = doc_root "../db/articles.rec"
	cmd = "recsel -t Article -c " articles_file
	cmd | getline line
	close(cmd)
	return int(line)
}

function get_article_by_id(doc_root, id, out,
						   #local
						   cmd, res, content_file, res2, line,
						   articles_file) {
	articles_file = doc_root "../db/articles.rec"
	cmd = "recsel -t Article -e \"ID = " id "\""
	cmd = cmd " " articles_file
	delete out
	res = ""
	while (cmd | getline line) { res = res line "\n" }
	close(cmd)
	rec_parse_record(res, out)
	content_file = sprintf("%s%s%d", doc_root, "../db/article/", id)
	res2 = ""
	while ((getline line < content_file) > 0) { res2 = res2 line "\n" }
	close(content_file)
	out["Content"] = res2
}

function get_all_articles(doc_root, out,
						  #local
						  start, page_size, end,
						  cmd, articles_file) {
	articles_file = doc_root "../db/articles.rec"
	cmd = "recsel -t Article "
	# `recsel` `-n` ranges are inclusive...
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
	cmd = cmd " " articles_file
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

function create_article(doc_root, title, content,
						#local
						time, newid, article_content_file,
						article_comment_template_file, article_comment_file, line, c,
						cmd, articles_file) {
	articles_file = doc_root "../db/articles.rec"
	newid = count_article(doc_root) + 1
	cmd = "recins -t Article "
	cmd = cmd sprintf("-f ID -v %d ", newid)
	cmd = cmd sprintf("-f Title -v \"%s\" ", title)
	"date" | getline time
	cmd = cmd sprintf("-f Datetime -v \"%s\" ", time)
	cmd = cmd sprintf("-f Timestamp -v %d ", get_timestamp())
	cmd = cmd " " articles_file
	cmd = cmd " --verbose"
	cmd = cmd " >/dev/null"
	system(cmd)
	close(cmd)
	write_article_content(doc_root, newid, content)
	article_comment_template_file = doc_root "../templates/comments.rec"
	c = ""
	while ((getline line < article_comment_template_file) > 0) { c = c line "\n" }
	close(article_comment_template_file)
	article_comment_file = doc_root sprintf("../db/comment/%d.rec", newid)
	print(c) > article_comment_file
	close(article_comment_file)
}

function write_article_content(doc_root, newid, content,
							   #local
							   article_content_file) {
	article_content_file = doc_root sprintf("../db/article/%d", newid)
	print(content) > article_content_file
	close(article_content_file)
}

function update_article(doc_root, id, title, content,
						#local
						time, newid, article_content_file,
						article_comment_template_file, article_comment_file, line, c,
						cmd, articles_file) {
	articles_file = doc_root "../db/articles.rec"
	cmd = sprintf("recset -t Article -e \"ID = %s\" ", id)
	cmd = cmd sprintf("-f Title -s \"%s\" ", title)
	cmd = cmd " " articles_file
	cmd = cmd " --verbose"
	cmd = cmd " >/dev/null"
	system(cmd)
	close(cmd)
	write_article_content(doc_root, id, content)
}

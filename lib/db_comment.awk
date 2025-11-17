
function count_comment(doc_root, article_id,
					   # local vars
					   cmd, cmd_count_str, comments_file) {
	comments_file = doc_root "../db/comment/" article_id ".rec"
	cmd = "recsel -t Comment -c " comments_file
	cmd | getline cmd_count_str
	return int(cmd_count_str)
}

# returns all comment.
# comments are returned in the form of strings; you need to parse them manually.
function get_all_comments_of_article(doc_root, article_id, out,
									 #local
									 cmd, out1, res,
									 comments_file) {
	comments_file = doc_root "../db/comment/" article_id ".rec"
	delete out
	cmd = "recsel -t Comment " comments_file
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

function new_comment(doc_root, article_id,
					 name, email, website, content,
					 #local
					 cmd, target_id,
					 datestr,
					 comments_file) {
	comments_file = doc_root "../db/comment/" article_id ".rec"
	target_id = count_comment(doc_root, article_id) + 1
	cmd = "recins -t Comment -f ID -v " target_id
	cmd = cmd " -f Name -v \"" name "\""
	cmd = cmd " -f Email -v \"" email "\""
	cmd = cmd " -f Website -v \"" website "\""
	"date" | getline datestr
	cmd = cmd " -f Datetime -v \"" datestr "\""
	cmd = cmd " -f Content -v \"" content "\""
	cmd = cmd " " comments_file
	cmd = cmd " --verbose"
	cmd = cmd " >/dev/null"
    # print cmd > "/dev/stderr"
	system(cmd)
}

function get_comment_by_id(doc_root, article_id, comment_id, out,
						   #local
						   line, res,
						   cmd, comments_file) {
	comments_file = doc_root "../db/comment/" article_id ".rec"
	cmd = sprintf("recsel -t Comment -e \"ID = %s\"", comment_id)
	cmd = cmd " " comments_file
	res = ""
	while (cmd | getline line) { res = res line "\n" }
	close(cmd)
	rec_parse_record(res, out)
}

function update_comment_by_id(doc_root, article_id, comment_id,
							  name, email, website, content,
							  #local
							  cmd, comments_file) {
	comments_file = doc_root "../db/comment/" article_id ".rec"
	cmd = sprintf("recins -t Comment -e \"ID = %s\" ", comment_id)
	cmd = cmd sprintf("-f ID -v \"%s\" ", comment_id)
	cmd = cmd sprintf("-f Name -v \"%s\" ", name)
	cmd = cmd sprintf("-f Title -v \"%s\" ", title)
	cmd = cmd sprintf("-f Email -v \"%s\" ", email)
	cmd = cmd sprintf("-f Website -v \"%s\" ", website)
	cmd = cmd sprintf("-f Content -v \"%s\" ", content)
	cmd = cmd " " comments_file
	cmd = cmd " --verbose"
	cmd = cmd " >/dev/null"
	system(cmd)
	close(cmd)
}


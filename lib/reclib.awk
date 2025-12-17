@namespace "reclib"

# copied from
#     https://www.gnu.org/software/gawk/manual/html_node/Join-Function.html
function join(array, start, end, sep,    result, i)
{
    if (sep == "")
       sep = " "
    else if (sep == SUBSEP) # magic value
       sep = ""
    result = array[start]
    for (i = start + 1; i <= end; i++)
        result = result sep array[i]
    return result
}

function parse_record(str, out,
					  # local var
					  n, lines, key, val,
					  ml, ml_key, ml_res, tmp,
					  matchres) {
	n = split(str, lines, /\n/)
	delete out
	delete ml
	ml_key = ""
	for (i = 1; i <= n; i++) {
		if (substr(lines[i], 1, 1) == "+") {
			if (substr(lines[i], 2, 1) == " ") {
				ml[length(ml)+1] = substr(lines[i], 3)
			} else {
				ml[length(ml)+1] = substr(lines[i], 2)
			}
			continue
		}
		match(lines[i], /([a-zA-Z%][a-zA-Z0-9_]*):[ \t](.*)/, matchres)
		if (matchres[0] != "") {
			key = matchres[1]
			val = matchres[2]
			if (length(ml) > 1) {
				ml_res = join(ml, 1, length(ml), "\n")
				if (isarray(out[ml_key])) {
					out[ml_key][length(out[ml_key])] = ml_res
				} else {
					out[ml_key] = ml_res
				}
				delete ml
			}
			if (key in out) {
				if (!isarray(out[key])) {
					tmp = out[key]
					delete out[key]
					out[key][1] = tmp
				}
				out[key][length(out[key])+1] = val
				ml_key = key
				ml[1] = val
			} else {
				out[key] = val
				ml_key = key
				ml[1] = val
			}
		}
	}
	if (length(ml) > 1) {
		ml_res = join(ml, 1, length(ml), "\n")
		if (awk::isarray(out[ml_key])) {
			out[ml_key][length(out[ml_key])] = ml_res
		} else {
			out[ml_key] = ml_res
		}
	}
}


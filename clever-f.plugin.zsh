cleverf() {
	local search_type=$1

    # vi-find-next-charでキャンセルされるよりも前に初期化しておく
    cleverf-reset-prev-match

	if [[ ! -v prev_cursor_pos ]]; then
		prev_cursor_pos=-1
	fi

	cleverf-match ${search_type} ${prev_cursor_pos}

    if [[ $? -ne 0 ]]; then
        return
    fi

	# global
	prev_cursor_pos=${CURSOR}

	cleverf-highlight-all
}

cleverf-match() {
	local search_type=$1
	local tmp_prev_cursor_pos=$2

	if [[ ${search_type} ]]; then
		cleverf-vi-find-next ${tmp_prev_cursor_pos}
	else 
		# cleverf-vi-find-prev
	fi

	if [ $? -eq 0 ]; then
		return 0
	fi

	return 1
}

cleverf-vi-find-next() {
	local tmp_prev_cursor_pos=$1
	local current_cursor_pos=${CURSOR}

	if [[ ${tmp_prev_cursor_pos} -ne ${current_cursor_pos} ]]; then
		zle vi-find-next-char

		if [[ $? -eq 0 ]]; then
			return 0
		fi
	fi

	local is_current_line=true
	for line in {1..$BUFFERLINES}; do
		zle .vi-repeat-find

		if [[ $? -eq 0 ]]; then
			if ! "${is_current_line}"; then
				# 次の行マッチの1文字目がヒットできないので戻す
				zle .vi-rev-repeat-find
			fi

			return 0
		fi

		# 次のラインの先頭に移動する
		# 次のラインに移動しない行末移動
		zle .vi-end-of-line
		# 次のラインに移動する行末移動
		zle .end-of-line
		# 前のラインに移動しない行頭移動
		zle .vi-beginning-of-line

		is_current_line=false
	done

	return 1
}

cleverf-highlight-all() {
    local cursor_position_char=${RBUFFER:0:1}

    # 1文字ずつ
    # echo で制御文字が消えるっぽい
	local buffer_len=$(cleverf-get-length ${BUFFER})
	local buffer_string=$(echo ${BUFFER})

    for index in {0..$buffer_len}; do
        local char=${buffer_string:${index}:1}

        if [[ $char = $cursor_position_char ]]; then
            cleverf-highlight ${index}
        fi
    done
}

cleverf-get-length() {
	echo $(($(echo $1 | wc -m)-1))
}

cleverf-next() {
	cleverf 1
}

cleverf-prev() {
	cleverf 2
}

cleverf-reset-prev-match() {
    prev_pos=-1
    is_found=true
    region_highlight=()
}

cleverf-highlight() {
    region_highlight+=("$1 $(($1+1)) bold,fg=red")
}

# 初期化
cleverf-reset-prev-match

zle -N cleverf-next
bindkey "^N" cleverf-next

zle -N cleverf-prev
bindkey "^G" cleverf-prev

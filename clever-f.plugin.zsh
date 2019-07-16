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

	cleverf-repeat-match ${tmp_prev_cursor_pos}
	if [ $? -eq 0 ]; then
		return 0
	fi

	cleverf-vi-find ${search_type}
	if [ $? -eq 0 ]; then
		return 0
	fi

	return 1
}

cleverf-repeat-match() {
	local tmp_prev_cursor_pos=$1
	local current_cursor_pos=${CURSOR}

    if [[ ${tmp_prev_cursor_pos} -eq ${current_cursor_pos} ]]; then
		local cursor_pos=${current_cursor_pos}

		for line in ${RBUFFER}; do
			echo $line
			zle .vi-repeat-find 2> /dev/null

			if [[ $? -eq 0 ]]; then
				return 0
			fi

			CURSOR+=$(cleverf-get-length ${line})
		done
    fi

	# カーソル位置を戻して終了
	CURSOR=${current_cursor_pos}

	return 1
}

cleverf-vi-find() {
	if [[ $1 -eq 1 ]]; then
		zle .vi-find-next-char
	elif [[ $1 -eq 2 ]]; then
		zle .vi-find-prev-char
	else
		return 1
	fi

	if [[ $? -eq 0 ]]; then
		return 0
	fi

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

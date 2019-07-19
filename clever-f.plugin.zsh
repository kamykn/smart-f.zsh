local search_type_next=1
local search_type_prev=2

cleverf() {
	local search_type=$1

	# vi-find-next-charでキャンセルされるよりも前に初期化しておく
	cleverf-reset-highlight

	if [[ ! -v prev_cursor_pos ]]; then
		prev_cursor_pos=-1
	fi

	cleverf-vi-find ${search_type} ${prev_cursor_pos}

	if [[ $? -ne 0 ]]; then
		return
	fi

	# global
	prev_cursor_pos=${CURSOR}

	cleverf-highlight-all
}

cleverf-vi-find() {
local search_type=$1
local tmp_prev_cursor_pos=$2
local current_cursor_pos=${CURSOR}

	# repeatじゃない場合
	if [[ ${tmp_prev_cursor_pos} -ne ${current_cursor_pos} ]]; then
		if [[ search_type -eq search_type_next ]]; then
			zle .vi-find-next-char
		else
			zle .vi-find-prev-char
		fi

		if [[ $? -eq 0 ]]; then
			return 0
		fi
	fi

	local is_current_line=true
	for line in {1..$BUFFERLINES}; do
		# repeatマッチ
		zle .vi-repeat-find

		if [[ $? -eq 0 ]]; then
			if ! "${is_current_line}"; then
				# 次/前の行マッチの1文字目がヒットできないので戻す
				if [[ search_type -eq search_type_next ]]; then
					zle .vi-rev-repeat-find
				else
					zle .vi-repeat-find
				fi
			fi

			return 0
		fi

		# 行移動
		if [[ search_type -eq search_type_next ]]; then
			cleverf-move-next-line
		else
			cleverf-move-prev-line
		fi

		is_current_line=false
	done

	return 1
}

# 次のラインの行頭に移動する
cleverf-move-next-line() {
# 次のラインに移動しない行末移動
zle .vi-end-of-line
# 次のラインに移動する行末移動
zle .end-of-line
# 前のラインに移動しない行頭移動
zle .vi-beginning-of-line
}

# 前のラインの行末に移動する
cleverf-move-prev-line() {
# 前のラインに移動しない行頭移動
zle .vi-beginning-of-line
# 前のラインに移動する行頭移動
zle .beginning-of-line
# 次のラインに移動しない行末移動
zle .vi-end-of-line
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
cleverf search_type_next
}

cleverf-prev() {
cleverf search_type_prev
}

cleverf-reset-highlight() {
region_highlight=()
}

cleverf-highlight() {
region_highlight+=("$1 $(($1+1)) bold,fg=red")
}

# 初期化
cleverf-reset-highlight

zle -N cleverf-next
bindkey "^X^F" cleverf-next

zle -N cleverf-prev
bindkey "^X^N" cleverf-prev

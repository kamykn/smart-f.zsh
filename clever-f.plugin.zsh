local search_type_next=1
local search_type_prev=2
local search_type_mode=0

clever-f() {
	local search_type=$1

	if [[ ! -v prev_cursor_pos ]]; then
		prev_cursor_pos=-1
	fi

	clever-f-vi-find ${search_type} ${prev_cursor_pos}

	if [[ $? -ne 0 ]]; then
		if [[ $tmp_prev_cursor_pos = $CURSOR ]]; then
			clever-f-reset-highlight
		fi

		return
	fi

	# global
	prev_cursor_pos=${CURSOR}

	clever-f-highlight-all
}

clever-f-vi-find() {
	local search_type=$1
	local tmp_prev_cursor_pos=$2
	local current_cursor_pos=${CURSOR}

	if [[ $tmp_prev_cursor_pos -ne $current_cursor_pos ]]; then
		clever-f-find $search_type

		if [[ $? -eq 0 ]]; then
			return 0
		fi
	fi

	clever-f-repeat-find-loop $search_type

	if [[ $? -eq 0 ]]; then
		return 0
	fi

	return 1
}

clever-f-find() {
	local search_type=$1

	if [[ $search_type -eq $search_type_next ]]; then
		zle .vi-find-next-char
	else
		zle .vi-find-prev-char
	fi

	if [[ $? -eq 0 ]]; then
		search_type_mode=$search_type
		return 0
	fi

	return 1
}

clever-f-repeat-find-loop() {
	local search_type=$1

	local current_line=$(echo "$LBUFFER" | wc -l | tr -d ' ')
	local end_line=1

	if [[ $search_type -eq $search_type_next ]]; then
		end_line=${BUFFERLINES}
	else
		end_line=1
	fi

	local is_current_line=true
	for line in $(seq ${current_line} ${end_line}); do
		if [[ line -ne $current_line ]]; then
			is_current_line=false
		fi

		clever-f-repeat-find $search_type $is_current_line
		if [[ $? -eq 0 ]]; then
			return 0
		fi
	done

	# 無かった場合にカーソル位置を戻す
	CURSOR=$current_cursor_pos

	return 1
}

clever-f-repeat-find() {
	local search_type=$1
	local is_current_line=$2

	# 行移動
	if ! "${is_current_line}"; then
		if [[ $search_type -eq $search_type_next ]]; then
			clever-f-move-next-line
		else
			clever-f-move-prev-line
		fi
	fi

	# repeatマッチ
	if [[ $search_type_mode -eq $search_type ]]; then
		zle .vi-repeat-find
	else
		# repeatを逆向きにする用
		zle .vi-rev-repeat-find
	fi

	if [[ $? -eq 0 ]]; then
		if ! "${is_current_line}"; then
			# 次/前の行マッチの1文字目がヒットできないので戻す
			if [[ $search_type -eq $search_type_next ]]; then
				zle .vi-rev-repeat-find
			else
				zle .vi-repeat-find
			fi
		fi

		return 0
	fi

	return 1
}

# 次のラインの行頭に移動する
clever-f-move-next-line() {
	# 次のラインに移動しない行末移動
	zle .vi-end-of-line
	# 次のラインに移動する行末移動
	zle .end-of-line
	# 前のラインに移動しない行頭移動
	zle .vi-beginning-of-line
}

# 前のラインの行末に移動する
clever-f-move-prev-line() {
	# 前のラインに移動しない行頭移動
	zle .vi-beginning-of-line
	# 前のラインに移動する行頭移動
	zle .beginning-of-line
	# 次のラインに移動しない行末移動
	zle .vi-end-of-line
}

clever-f-highlight-all() {
	local cursor_position_char=${RBUFFER:0:1}

	# 1文字ずつ
	# echo で制御文字が消えるっぽい
	local buffer_len=$(clever-f-get-length ${BUFFER})
	local buffer_string=$(echo ${BUFFER})

	for index in {0..$buffer_len}; do
		local char=${buffer_string:${index}:1}

		if [[ $char = $cursor_position_char ]]; then
			clever-f-highlight ${index}
		fi
	done
}

clever-f-get-length() {
	echo $(($(echo $1 | wc -m)-1))
}

clever-f-next() {
	clever-f $search_type_next
}

clever-f-prev() {
	clever-f $search_type_prev
}

clever-f-reset-highlight() {
	region_highlight=()
}

clever-f-highlight() {
	region_highlight+=("$1 $(($1+1)) bold,fg=red")
}

# 初期化
clever-f-reset-highlight

zle -N clever-f-next
zle -N clever-f-prev

# for emacs mode
bindkey "^X^F" clever-f-next

# for vi mode
bindkey -a 'f' clever-f-next
bindkey -a 'F' clever-f-prev

# Copyright (c) 2019 kamykn.

# Character search function extension plugin.

if [[ ! -v CLEVER_F_SEARCH_TYPE_NEXT ]]; then
    readonly -i CLEVER_F_SEARCH_TYPE_NEXT=1
fi

if [[ ! -v CLEVER_F_SEARCH_TYPE_PREV ]]; then
    readonly -i CLEVER_F_SEARCH_TYPE_PREV=2
fi

# forward or backward mode
if [[ ! -v clever_f_search_type_mode ]]; then
	local -i clever_f_search_type_mode=0
fi

# t or f mode
if [[ ! -v clever_f_is_f_search ]]; then
	local -i clever_f_is_f_search=0
fi

_clever_f() {
    local -i search_type=$1
    clever_f_is_f_search=$2

    if [[ ! -v prev_cursor_pos ]]; then
        prev_cursor_pos=-1
    fi

    _clever_f_vi_find ${search_type} ${prev_cursor_pos}

    if [[ $? -ne 0 ]]; then
        if [[ ${tmp_prev_cursor_pos} = ${CURSOR} ]]; then
            _clever_f_reset_highlight
        fi

        return 1
    fi

    # global
    prev_cursor_pos=${CURSOR}

    _clever_f_highlight_all ${search_type}

    return 0
}

_clever_f_vi_find() {
    local -i search_type=$1
    local -i tmp_prev_cursor_pos=$2
    local -i current_cursor_pos=${CURSOR}

    if [[ ${tmp_prev_cursor_pos} -ne ${current_cursor_pos} ]]; then
        _clever_f_find ${search_type}

        if [[ $? -eq 0 ]]; then
            return 0
        fi
    fi

    _clever_f_repeat_find_loop ${search_type}

    if [[ $? -eq 0 ]]; then
        return 0
    fi

    return 1
}

_clever_f_find() {
    local -i search_type=$1

    if [[ ${search_type} -eq ${CLEVER_F_SEARCH_TYPE_NEXT} ]]; then
		if [[ ${clever_f_is_f_search} -eq 0 ]]; then
			zle .vi-find-next-char
		else
			zle .vi-find-next-char-skip
		fi
    else
		if [[ ${clever_f_is_f_search} -eq 0 ]]; then
			zle .vi-find-prev-char
		else
			zle .vi-find-prev-char-skip
		fi
    fi

    if [[ $? -eq 0 ]]; then
        clever_f_search_type_mode=${search_type}
        return 0
    fi

    return 1
}

_clever_f_repeat_find_loop() {
    local -i search_type=$1

    local -i current_line=$(echo "${LBUFFER}" | wc -l | tr -d ' ')
    local -i end_line=1

    if [[ ${search_type} -eq ${CLEVER_F_SEARCH_TYPE_NEXT} ]]; then
        end_line=${BUFFERLINES}
    else
        end_line=1
    fi

    local is_current_line=true
    for line in $(seq ${current_line} ${end_line}); do
        if [[ line -ne $current_line ]]; then
            is_current_line=false
        fi

        _clever_f_repeat_find ${search_type} ${is_current_line}
        if [[ $? -eq 0 ]]; then
            return 0
        fi
    done

    # reset cursor position
    CURSOR=${current_cursor_pos}

    return 1
}

_clever_f_repeat_find() {
    local -i search_type=$1
    local is_current_line=$2

    # move line
    if ! "${is_current_line}"; then
        if [[ ${search_type} -eq ${CLEVER_F_SEARCH_TYPE_NEXT} ]]; then
            _clever_f_move_next_line
        else
            _clever_f_move_prev_line
        fi
    fi

    if [[ ${clever_f_search_type_mode} -eq ${search_type} ]]; then
		# for repeat
		zle .vi-repeat-find
    else
        # for reverse repeat
        zle .vi-rev-repeat-find
    fi

    if [[ $? -eq 0 ]]; then
        if ! "${is_current_line}"; then
            # 次/前の行マッチの1文字目がヒットできないので戻す
            if [[ ${search_type} -eq ${CLEVER_F_SEARCH_TYPE_NEXT} ]]; then
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
_clever_f_move_next_line() {
    # 次のラインに移動しない行末移動
    zle .vi-end-of-line
    # 次のラインに移動する行末移動
    zle .end-of-line
    # 前のラインに移動しない行頭移動
    zle .vi-beginning-of-line

    return 0
}

# 前のラインの行末に移動する
_clever_f_move_prev_line() {
    # 前のラインに移動しない行頭移動
    zle .vi-beginning-of-line
    # 前のラインに移動する行頭移動
    zle .beginning-of-line
    # 次のラインに移動しない行末移動
    zle .vi-end-of-line

    return 0
}

_clever_f_highlight_all() {
    local -i search_type=$1
	local cursor_position_char=$(_clever_f_find_char ${search_type})

    # 1文字ずつ
    # echo で制御文字が消えるっぽい
    local -i buffer_len=$(_clever_f_get_length ${BUFFER})
    local buffer_string=$(echo ${BUFFER})

    for index in {0..${buffer_len}}; do
        local char=${buffer_string:${index}:1}

        if [[ ${char} = ${cursor_position_char} ]]; then
            _clever_f_highlight ${index}
        fi
    done

    return 0
}

_clever_f_find_char() {
    local -i search_type=$1
	local -i cursor_position_char_index=0
	local buffer_for_find=$RBUFFER

    if [[ ${search_type} -eq ${CLEVER_F_SEARCH_TYPE_NEXT} ]]; then
		if [[ ${clever_f_is_f_search} -ne 0 ]]; then
			cursor_position_char_index=1
		fi
	else
		if [[ ${clever_f_is_f_search} -ne 0 ]]; then
			buffer_for_find=$LBUFFER
			cursor_position_char_index=$(($(_clever_f_get_length ${LBUFFER})-1))
		fi
	fi

	local cursor_position_char=${buffer_for_find:${cursor_position_char_index}:1}

	echo $cursor_position_char
	return 0
}

_clever_f_get_length() {
    echo $(($(echo $1 | wc -m)-1))
    return 0
}

_clever_f_highlight() {
    region_highlight+=("$1 $(($1+1)) bold,fg=red")
    return 0
}

_clever_f_reset_highlight() {
    region_highlight=()
    return 0
}

clever_f_next() {
    _clever_f ${CLEVER_F_SEARCH_TYPE_NEXT} 0
    return 0
}

clever_f_prev() {
    _clever_f ${CLEVER_F_SEARCH_TYPE_PREV} 0
    return 0
}

clever_f_next_skip() {
    _clever_f ${CLEVER_F_SEARCH_TYPE_NEXT} 1
    return 0
}

clever_f_prev_skip() {
    _clever_f ${CLEVER_F_SEARCH_TYPE_PREV} 1
    return 0
}

_clever_f_bind_reset_highlight() {
	local -U widgets_to_bind
	widgets_to_bind=(${${(k)widgets}:#(.*|run-help|which-command|beep|set-local-history|yank|yank-pop)})

	for cur_widget in $widgets_to_bind; do
		case ${widgets[$cur_widget]:-""} in
			builtin)
				eval "_clever_f_call_widget_$cur_widget() {
					builtin zle .$cur_widget
					_clever_f_reset_highlight
				}"

				zle -N $cur_widget _clever_f_call_widget_$cur_widget
		esac
	done
}


# initialization
_clever_f_reset_highlight

# bind for reset highlight
_clever_f_bind_reset_highlight

zle -N clever_f_next
zle -N clever_f_prev
zle -N clever_f_next_skip
zle -N clever_f_prev_skip

# for emacs mode
bindkey "^X^F" clever_f_next

# for vi mode
bindkey -a 'f' clever_f_next
bindkey -a 'F' clever_f_prev
bindkey -a 't' clever_f_next_skip
bindkey -a 'T' clever_f_prev_skip

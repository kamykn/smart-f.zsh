cleverf() {
    local tmp_prev_pos=$prev_pos

    # vi-find-next-charでキャンセルされるよりも前に初期化しておく
    cleverf-reset-prev-match

    local current_pos=$((${#LBUFFER}+1))
    local is_repeat_found=false
    if [[ $tmp_prev_pos -eq $current_pos ]]; then
        zle .vi-repeat-find 2> /dev/null

        if [[ $? -eq 0 ]]; then
            is_repeat_found=true
            is_found=true
        fi
    fi

    if ! $is_repeat_found; then
        zle .vi-find-next-char

        if [[ $? -eq 0 ]]; then
            is_found=true
        fi
    fi

    if ! $is_found; then
        return
    fi

    prev_pos=$((${#LBUFFER}+1))
    local cursor_position_char=${RBUFFER:0:1}

    # 1文字ずつ
    # echo で制御文字が消えるっぽい
    buffer_len=$((`echo ${BUFFER} | wc -m`-1))
    buffer_string=`echo ${BUFFER}`

    for index in {0..$buffer_len}; do
        local char=${buffer_string:${index}:1}

        if [[ $char = $cursor_position_char ]]; then
            cleverf-highlight ${index}
        fi
    done
}

cleverf-reset-prev-match() {
    prev_pos=-1
    is_found=true
    region_highlight=()
}

cleverf-highlight() {
    region_highlight+=("$1 $(($1+1)) bold,fg=red")
}

cleverf-reset-prev-match

zle -N cleverf
bindkey "^N" cleverf

# Copyright (c) 2019 kamykn.

# Character search function extension plugin.

_smart_f_set_global() {
    # Constant
    if [[ ! -v SMART_F_SEARCH_FORWARD ]]; then
        SMART_F_SEARCH_FORWARD=1
    fi

    if [[ ! -v SMART_F_SEARCH_BACKWARD ]]; then
        SMART_F_SEARCH_BACKWARD=2
    fi

    if [[ ! -v SMART_F_SEARCH_TYPE_F ]]; then
        SMART_F_SEARCH_TYPE_F=1
    fi

    if [[ ! -v SMART_F_SEARCH_TYPE_T ]]; then
        SMART_F_SEARCH_TYPE_T=2
    fi

    # Global
    # highlight setting
    if [[ ! -v Smart_f_region_highlight_setting ]]; then
		Smart_f_region_highlight_setting=()
    fi

    # forward or backward mode
    if [[ ! -v Smart_f_search_direction ]]; then
        Smart_f_search_direction=0
    fi

    # t or f mode
    if [[ ! -v Smart_f_current_search_type ]]; then
        Smart_f_current_search_type=0
    fi

	# current search character
    if [[ ! -v Smart_f_current_char ]]; then
        Smart_f_current_char=''
    fi

    if [[ ! -v Smart_f_is_repeat ]]; then
        Smart_f_is_repeat=false
    fi

    return 0
}

_smart_f() {
    local -i search_direction=$1
    local -i search_type=$2

    if [[ ! -v Prev_cursor_pos ]]; then
        Prev_cursor_pos=-1
    fi

    _smart_f_find ${search_direction} ${search_type} ${Smart_f_is_repeat}

    if [[ $? -eq 0 ]]; then
        Prev_cursor_pos=${CURSOR}

        if ! "${Smart_f_is_repeat}"; then
            _smart_f_highlight_all ${search_direction} ${search_type}
        fi

        Smart_f_is_repeat=true
        return 0
    fi

    return 0
}

_smart_f_find() {
    local -i search_direction=$1
    local -i search_type=$2
    local is_repeat=$3

    if ! "${is_repeat}"; then
        read -k1 Smart_f_current_char
    fi

    local buffer_string=$(echo ${BUFFER})

    for index in $(_get_buffer_index_range ${search_direction} ${is_repeat}); do
        local char=${buffer_string:${index}:1}

        if [[ ${char} = ${Smart_f_current_char} ]]; then
            if [[ ${search_type} -eq ${SMART_F_SEARCH_TYPE_F} ]];then
                cursor_pos=$index
            else
                if [[ ${search_direction} -eq ${SMART_F_SEARCH_FORWARD} ]]; then
                    cursor_pos=$(($index-1))
                else
                    cursor_pos=$(($index+1))
                fi
            fi

            CURSOR=${cursor_pos}

            Smart_f_search_direction=${search_direction}
            Smart_f_current_search_type=${search_type}

            return 0
        fi
    done

    return 1
}

_get_buffer_index_range() {
    local -i search_direction=$1
    local is_repeat=$2

    # 1文字ずつ
    # echo で制御文字が消えるっぽい
    local -i buffer_len=$(_smart_f_get_length ${BUFFER})

    if [[ $search_direction -eq ${SMART_F_SEARCH_FORWARD} ]]; then
        if "${is_repeat}"; then
            loop_start=$((${CURSOR}+1))
        else
            loop_start=0
        fi

        loop_end=${buffer_len}
    else
        if "${is_repeat}"; then
            loop_start=$((${CURSOR}-1))
        else
            loop_start=${buffer_len}
        fi

        loop_end=0
    fi

    echo $(seq ${loop_start} ${loop_end})
}

# 次のラインの行頭に移動する
_smart_f_move_next_line() {
    # 複数行移動する場合にはwidgetの先頭に.をつけると移動できない
    # 次のラインに移動しない行末移動
    zle vi-end-of-line
    # 次のラインに移動する行末移動
    zle end-of-line
    # 前のラインに移動しない行頭移動
    zle vi-beginning-of-line

    return 0
}

# 前のラインの行末に移動する
_smart_f_move_prev_line() {
    # 複数行移動する場合にはwidgetの先頭に.をつけると移動できない
    # 前のラインに移動しない行頭移動
    zle vi-beginning-of-line
    # 前のラインに移動する行頭移動
    zle beginning-of-line
    # 次のラインに移動しない行末移動
    zle vi-end-of-line

    return 0
}

_smart_f_highlight_all() {
    local -i search_direction=$1
    local -i search_type=$2

    local cursor_position_char=$(_smart_f_find_char ${search_direction} ${search_type})

    # 1文字ずつ
    # echo で制御文字が消えるっぽい
    local -i buffer_len=$(_smart_f_get_length ${BUFFER})
    local buffer_string=$(echo ${BUFFER})

    if [[ $search_direction -eq ${SMART_F_SEARCH_FORWARD} ]]; then
        loop_start=${buffer_len}
        loop_end=0
    else
        loop_start=0
        loop_end=${buffer_len}
    fi

    _smart_f_store_highlight_setting

    local is_find=false
    for index in $(seq ${loop_start} ${loop_end}); do
        local char=${buffer_string:${index}:1}
        local is_find_prev=$is_find
        is_find=false

        if [[ ${char} = ${cursor_position_char} ]]; then
            if [[ ${search_type} -eq ${SMART_F_SEARCH_TYPE_F} ]];then
                _smart_f_highlight ${index}
            fi

            is_find=true
        fi

        if "${is_find_prev}"; then
            if [[ ${search_type} -eq ${SMART_F_SEARCH_TYPE_T} ]];then
                _smart_f_highlight ${index}
            fi
        fi
    done

    return 0
}

_smart_f_find_char() {
    local -i search_direction=$1
    local -i search_type=$2
    local -i cursor_position_char_index=0
    local buffer_for_find=$RBUFFER

    if [[ ${search_direction} -eq ${SMART_F_SEARCH_FORWARD} ]]; then
        if [[ ${search_type} -eq ${SMART_F_SEARCH_TYPE_T} ]]; then
            cursor_position_char_index=1
        fi
    else
        if [[ ${search_type} -eq ${SMART_F_SEARCH_TYPE_T} ]]; then
            buffer_for_find=$LBUFFER
            cursor_position_char_index=$(($(_smart_f_get_length ${LBUFFER})-1))
        fi
    fi

    local cursor_position_char=${buffer_for_find:${cursor_position_char_index}:1}

    echo $cursor_position_char
    return 0
}

_smart_f_get_length() {
    echo $(($(echo $1 | wc -m)-1))
    return 0
}

_smart_f_get_num_of_lines() {
    echo $(echo $1 | wc -l)
    return 0
}

_smart_f_store_highlight_setting() {
    Smart_f_region_highlight_setting=$region_highlight
    return 0
}

_smart_f_highlight() {
    region_highlight+=("$1 $(($1+1)) bold,fg=red")
    return 0
}

_smart_f_reset_highlight() {
    region_highlight=()

    for highlight_setting in $Smart_f_region_highlight_setting; do
        region_highlight+=$highlight_setting
    done

    Smart_f_is_repeat=false

    return 0
}

smart_f_next() {
    _smart_f_set_global
    _smart_f ${SMART_F_SEARCH_FORWARD} ${SMART_F_SEARCH_TYPE_F}
    return 0
}

smart_f_prev() {
    _smart_f_set_global
    _smart_f ${SMART_F_SEARCH_BACKWARD} ${SMART_F_SEARCH_TYPE_F}
    return 0
}

smart_f_next_skip() {
    _smart_f_set_global
    _smart_f ${SMART_F_SEARCH_FORWARD} ${SMART_F_SEARCH_TYPE_T}
    return 0
}

smart_f_prev_skip() {
    _smart_f_set_global
    _smart_f ${SMART_F_SEARCH_BACKWARD} ${SMART_F_SEARCH_TYPE_T}
    return 0
}

_smart_f_bind_reset_highlight() {
    local -U widgets_to_bind
    widgets_to_bind=(${${(k)widgets}:#(.*|run-help|which-command|beep|set-local-history|yank|yank-pop)})

    for cur_widget in $widgets_to_bind; do
        case ${widgets[$cur_widget]:-""} in
            builtin)
                eval "_smart_f_call_widget_$cur_widget() {
                    builtin zle .$cur_widget
                    _smart_f_reset_highlight
                }"

            zle -N $cur_widget _smart_f_call_widget_$cur_widget
        esac
    done
}

# __smart_f_hl_debug() {
#     region_highlight+=("1 2 bold,fg=blue")
# }
#
# zle -N __smart_f_hl_debug
# bindkey "^E" __smart_f_hl_debug

# initialization
_smart_f_reset_highlight

# bind for reset highlight
_smart_f_bind_reset_highlight

zle -N smart_f_next
zle -N smart_f_prev
zle -N smart_f_next_skip
zle -N smart_f_prev_skip

# for emacs mode
bindkey "^X^F" smart_f_next

# for vi mode
bindkey -a 'f' smart_f_next
bindkey -a 'F' smart_f_prev
bindkey -a 't' smart_f_next_skip
bindkey -a 'T' smart_f_prev_skip

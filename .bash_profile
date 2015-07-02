#!/bin/bash

if [[ -z $TERM ]]; then
    export TERM=dumb
fi

function set_locales() {
    if [[ -z "$LANG" ]]; then
        export LANG='en_US.UTF-8'
    fi

    if [[ -z "$LC_ALL" ]]; then
        export LC_ALL=$LANG
    fi

    if [[ -z "$LANGUAGE" ]]; then
        export LANGUAGE='en_US:en'
    fi
}

function set_aliases() {
    alias pico='nano -E -T 4 -H -N -S -m -x -c'
    alias nano='nano -E -T 4 -H -N -S -m -x -c'
    alias ll='ls -lahG --color --time-style="+%Y-%m-%d"'
    alias ls='ls --color'

    alias rm='rm -i'
    alias cp='cp -i'
    alias mv='mv -i'

    export LS_COLORS="rs=0:di=01;32:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:"

    export EDITOR='nano -E -T 4 -H -N -S -m -x -c'
    export GIT_EDITOR='nano -E -T 4 -H -N -S -m -x -c'

    if ! shopt -oq posix; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
            . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
            . /etc/bash_completion
        fi
    fi
}

function _bash_prompt_get_git_state() {
    local GIT_STATE=""
    if [[ -n "$(git symbolic-ref HEAD 2>/dev/null)" ]]; then
        if [[ -n $(git status -s 2>/dev/null |grep -v ^# |grep -v "working directory clean") ]]; then
            GIT_STATE="$(tput setaf 1)✗"
        else
            GIT_STATE="$(tput setaf 2)✓"
        fi

        local GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

        GIT_STATE+="[git:${GIT_BRANCH}]$(tput sgr0)"
    fi

    echo -e " ${GIT_STATE}"
}

function _bash_prompt_get_user_color() {
    if [[ $(whoami) == "root" ]]; then
        local user_color=$(tput setaf 1)
    else
        local user_color=$(tput setaf 5)
    fi

    echo -e ${user_color}
}

function _bash_prompt_get_virtualenv() {
    local VIRTUALENV_PROMPT=""

    if [[ -n $VIRTUAL_ENV ]]; then
        VIRTUALENV_PROMPT="$(tput setab 5)[venv:$(echo ${VIRTUAL_ENV} | sed "s|${HOME}|~|")]$(tput sgr0)"
    fi

    echo -e ${VIRTUALENV_PROMPT}
}

function _bash_prompt_get_host_user_path() {
    local CWD=$(echo $(pwd) | sed "s|${HOME}|~|")
    local HOSTNAME=$(hostname -f | awk -F. '{print $1"."$2 }')
    local USERNAME=$(whoami)

    local USER_COLOR=$(_bash_prompt_get_user_color)

    local PROMPT="${USER_COLOR}[${USERNAME}]$(tput sgr0) "
    if [[ $(whoami) != "vagrant" && $(whoami) != "root" ]]; then
        PROMPT+="$(tput blink)$(tput setab 1)${HOSTNAME}$(tput sgr0) "
    else
        PROMPT+="$(tput setab 3)$(tput setaf 0)${HOSTNAME}$(tput sgr0) "
    fi
    PROMPT+="in $(tput setaf 6)${CWD}$(tput sgr0)"

    echo -e $PROMPT
}

function _bash_prompt_command() {
    local COLUMNS=$(tput cols)

    local PROMPT=$(_bash_prompt_get_host_user_path)
    local PROMPT_SIZE=$(echo -e ${PROMPT} | perl -pe 's/\e\[?.*?[\@-~]//g' | wc -c)

    local GIT_STATE=$(_bash_prompt_get_git_state)
    local GIT_STATE_SIZE=$(echo -e ${GIT_STATE} | perl -pe 's/\e\[?.*?[\@-~]//g' | awk ' { print length } ')

    local VIRTUALENV_PROMPT=$(_bash_prompt_get_virtualenv)
    local VIRTUALENV_PROMPT_SIZE=$(echo ${VIRTUALENV_PROMPT} | perl -pe 's/\e\[?.*?[\@-~]//g' | awk ' { print length } ')

    local spacing_witdth
    ((spacing_witdth=${COLUMNS}-${GIT_STATE_SIZE}-${PROMPT_SIZE}-${VIRTUALENV_PROMPT_SIZE}))
    local SPACING=""
    for i in $(seq 1 1 ${spacing_witdth}); do
        SPACING+=" "
    done

    PS1=${PROMPT}
    PS1+="${SPACING}"
    PS1+=${VIRTUALENV_PROMPT}${GIT_STATE}
    PS1+="\n→ "
}

function vagrant_gitconfig() {
    if [[ $(whoami) != "vagrant" ]]; then
        return
    fi

    exec 3>&1

    if [[ -z $(git config --global user.name) ]]; then
        clear
        nameAndSurname=$(dialog --title ".gitconfig settings" --inputbox "Podaj imię i nazwisko" 10 100 2>&1 1>&3)
        if [[ $? == 0 ]]; then
            git config --global user.name "$nameAndSurname"
        fi
        clear
    fi

    if [[ -z $(git config --global user.email) ]]; then
        clear
        email=$(dialog --title ".gitconfig settings" --inputbox "Podaj e-mail" 10 100 2>&1 1>&3)
        if [[ $? == 0 ]]; then
            git config --global user.email "$email"
        fi
        clear
    fi
}

vagrant_gitconfig
set_locales
set_aliases

PROMPT_COMMAND=_bash_prompt_command

#!/usr/bin/env sh
layout_dir=~/.config/screenlayout

dmenu_layouts() {
  cd "$layout_dir" || exit
  find . -name "*.sh" | dmenu -l 5 || exit | sh
}

dmenu_scripts() {
  get_functions | dmenu -l 5 || exit | eval
}

dmenu_cpma() {
  SERVER=$(echo "cpm.freddian.tf:27961
    cpm.freddian.tf:27960
    cpm.snapcase.net
    snapcase.net
    snapcase.net:27961
    51.38.83.66:27960
    82.196.10.31:27960
    188.226.192.203:27960
    188.226.192.203:27962" | dmenu -l 5)
  sh "$layout_dir"/singlescreen.sh
  cd ~/ioquake3 || exit
  ./ioquake3 +set fs_game cpma +connect "$SERVER"
}

dmenu_otp() {
  # thanks to https://gist.github.com/Alveel/d26c3b524d785af6fb0037394dd1f25e
  shopt -s nullglob globstar
  otp_dir_name=otp
  prefix=${PASSWORD_STORE_DIR-~/.password-store}
  otp_dirs=$(find $prefix -wholename "*/$otp_dir_name" | sed "s|$prefix/|$otp_dirs|g")
  otp_dir=$(printf '%s\n' "${otp_dirs[@]}" | dmenu "$@")
  [[ -n $otp_dir ]] || exit
  password_files=( "$prefix"/"$otp_dir"/*.gpg )
  password_files=( "${password_files[@]#"$prefix"/"$otp_dir"/}" )
  password_files=( "${password_files[@]%.gpg}" )
  password=$(printf '%s\n' "${password_files[@]}" | dmenu "$@")
  [[ -n $password ]] || exit
  pass otp show -c "$otp_dir"/"$password" 2>/dev/null
}

dmenu_bolt11() {
    clipboard=$(xclip -selection clipboard -o)
    prefix=$(echo "$clipboard" | cut -c 1-2 | tr '[:upper:]' '[:lower:]')
    if [[ "$prefix" != "ln" ]]; then
        notify-send "not a lightning invoice"
        exit 1
    fi
    decoded=$(bolt11 decode "$clipboard")
    [[ -z "$decoded" ]] && notify-send "decoding bolt11 failed" && exit 1
    selected=$(echo "$decoded" | jq -r | dmenu -l 30 || exit 1)
    [[ -z "$selected" ]] && exit 1
    if [[ "$selected" == "{"  ]]; then
        echo $decoded | jq -r | xclip -selection clipboard
    else
        echo $selected | xclip -selection clipboard
    fi
}

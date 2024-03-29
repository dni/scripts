#!/usr/bin/env sh

status_update() {
  VOL="$(pamixer --get-volume)%"
  DATE="$(date | cut -c -2) $(date +%d.%m.%Y)"
  TIME=$(date +%H:%M)

  EXTIP=$(cat ~/.cache/externalip)
  BTC=$(cat ~/.cache/btcprice)
  UPDATES=$(cat ~/.cache/updates)

  TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))C"
  AVAIL=$(df -h --output=avail | head -n4 | tail -n1)

  if acpi -a | grep off-line > /dev/null
  then
    BAT="Bat. $(acpi -b | awk '{ print $4  }' | tr -d ',')"
  else
    BAT="charging $(acpi -b | awk '{ print $4 }' | tr -d ',')"
  fi

  MSG=" ($BAT) | ♪ $VOL |  $TEMP |  $BTC | $AVAIL |  $DATE |  $TIME "

  xsetroot -name "$MSG"
  # xsetroot -name " ($UPDATES) | $EXTIP | ♪ $VOL |  $TEMP |  $BTC | $AVAIL |  $DATE |  $TIME "

}

externalip() {
  IP=$(wget http://checkip.dyndns.org/ -O - -o /dev/null | cut -d: -f 2 | cut -d\< -f 1)
  msg="External IP: $IP"
  notify-send "$msg"
  echo "$msg"
  echo "$IP" > ~/.cache/externalip
}

btcprice() {
  #get data and remove colors from output
  data=$(curl -s rate.sx/\?n=1 |
    sed 's/\x1B\[[0-9;]\+[A-Za-z]//g' | cat)

  price=$(echo "$data" |
    tail -n 6 |
    head -n 1 |
    cut -d " " -f 10
  )

  msg=$(echo "$data" |
    head -n 9 |
    tail -n 3
  )

  msg="$msg

   $price"

  dunstify "$msg"
  echo "$msg"
  echo "$price" > ~/.cache/btcprice
}

lnmticker() {
  #get data and remove colors from output
  data=$(lnm ticker)
  index=$(echo "$data" | grep index | cut -d " " -f 4 | cut -d "," -f 1)
  bid=$(echo "$data" | grep bid | cut -d " " -f 4 | cut -d "," -f 1)
  offer=$(echo "$data" | grep offer | cut -d " " -f 4)
  msg="Lnmarkets Ticker 
  index: $index
  bid: $bid
  offer: $offer"
  dunstify "$msg"
}

weather() {

  #get data and remove colors from output
  data=$(curl -s wttr.in/"$STATUS_WEATHER" | sed 's/\x1B\[[0-9;]\+[A-Za-z]//g' | cat)

  # get temp
  temp=$(echo "$data" |
    head -n 4 |
    tail -n 1 |
    sed 's/   */:/g' |
    cut -d : -f 4
  )

  # TODO: use icons for (rain|sun|cloudy|snow)
  msg="$STATUS_WEATHER: $temp"
  notify-send "$msg"
  echo "$msg"
  echo "$temp" > ~/.cache/weather # statusbar
}

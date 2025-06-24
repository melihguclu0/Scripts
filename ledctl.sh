#!/bin/bash
#set -x

CONFIG="$HOME/ledctl.bash"
source $CONFIG

help() {

    echo
    echo "ledctl"
    echo "version 0.5"
    echo
    echo "Script for controlling BLE Led Controller"
    echo
    echo "Usage: ledctl.sh [OPTION]..."
    echo
    echo "Options:"
    echo "  -s, set COLOR BRIGHTNESS          Set both color and brightness (000000-ffffff)"
    echo "  -b, brightness BRIGHTNESS         Set brightness level (0-100) or +,-"
    echo "  -n, next                          Switch to next color"
    echo "  -p, previous                      Switch to previous color"
    echo "  -x, sensor                        Digital light sensor support"
    echo "  -h, help                          Show this help message"
    echo
    echo "Commands:"
    echo "  on                                Turn on"
    echo "  off                               Turn off"
    echo "  red                               Set red"
    echo "  grn                               Set green"
    echo "  blu                               Set blue"
    echo
    echo "Examples:"
    echo "  ledctl.sh -s 00ff00 80                      "
    echo "  ledctl.sh on                                "
    echo "  ledctl.sh -b +                    Increase brightness by 10"
    echo "  ledctl.sh -b -                    Decrease brightness by 10"
    echo
}

sensor() {

    echo "Sensor Mode ON"
    LAST_STATE=""

    while true; do

        LINE=$(pinctrl get $DPIN)
        STATE=$(echo "$LINE" | cut -d' ' -f9)

        if [[ "$STATE" == "lo" && "$LAST_STATE" != "lo" ]]; then

            CID=$OFF
            DATA=$OFFD
    		echo "Leds OFF"
            gatttool -b "$MAC" --char-write-req -a "$HANDLE" -n "$DATA$CID"
            LAST_STATE="lo"

        elif [[ "$STATE" == "hi" && "$LAST_STATE" != "hi" ]]; then
            	
            CID=$ON
            DATA=$OND
    		echo "Leds ON"
            gatttool -b "$MAC" --char-write-req -a "$HANDLE" -n "$DATA$CID"
            LAST_STATE="hi"
        fi

        sleep 5

     done
}



refresh() {

    if [ ! -f "$CURRENT_CLR" ]; then
       echo "$RED" > "$CURRENT_CLR"
    fi

    if [ ! -f "$CURRENT_BRI" ]; then
       echo "50" > "$CURRENT_BRI"
    fi

    CID=$SCLR
    DATA=$(cat "$CURRENT_CLR" || echo $RED)

    echo "Color: $DATA"

    BRI=$(head -n 1 "$CURRENT_BRI")
    echo "Brightness: $BRI"

    R_HEX=${DATA:0:2}
    G_HEX=${DATA:2:2}
    B_HEX=${DATA:4:2}

    R_DEC=$((16#$R_HEX))
    G_DEC=$((16#$G_HEX))
    B_DEC=$((16#$B_HEX))

    R_NEW=$(( R_DEC * BRI / 100 ))
    G_NEW=$(( G_DEC * BRI / 100 ))
    B_NEW=$(( B_DEC * BRI / 100 ))

    R_FINAL=$(printf "%02x" $R_NEW)
    G_FINAL=$(printf "%02x" $G_NEW)
    B_FINAL=$(printf "%02x" $B_NEW)

    DATA="${R_FINAL}${G_FINAL}${B_FINAL}"

    echo "Writing: $DATA To: $MAC"
    gatttool -b "$MAC" --char-write-req -a "$HANDLE" -n "$DATA$CID"

}



case $1 in

    -h | help)
        help
        ;;

    on)
    	CID=$ON
    	DATA=$OND
    	gatttool -b "$MAC" --char-write-req -a "$HANDLE" -n "$DATA$CID"
    	;;

    off)
        CID=$OFF
    	DATA=$OFFD
    	gatttool -b "$MAC" --char-write-req -a "$HANDLE" -n "$DATA$CID"
    	;;

    set | -s)
    	CID=$SCLR
    	COL="${2}"
    	echo "color: 	  $COL"
    	BRI="${3}"
        echo "brightness: $BRI"
    	echo "$COL" > "$CURRENT_CLR"
    	echo "$BRI" > "$CURRENT_BRI"
    	refresh
        ;;

	-x | sensor)
		sensor
		;;

	greet)
        #Experimental Animation
		CID=$ON
	 	DATA=$RED
		gatttool -b "$MAC" --char-write-req -a "$HANDLE" -n "$DATA$CID"

    	CID=$S_BRT
        DATA=$A_BRT
    	gatttool -b "$MAC" --char-write-req -a "$HANDLE" -n "$DATA$CID"

    	sleep 1.5
    	refresh
  		;;

    red)
    	CID=$SCLR
    	DATA=$RED
    	echo "Setting Data: $DATA"
    	echo "$DATA" > "$CURRENT_CLR"
    	refresh
    	;;

    grn)
    	CID=$SCLR
    	DATA=$GRN
    	echo "Setting Data: $DATA"
    	echo "$DATA" > "$CURRENT_CLR"
    	refresh
    	;;

    blu)
    	CID=$SCLR
    	DATA=$BLU
    	echo "Setting Data: $DATA"
    	echo "$DATA" > "$CURRENT_CLR"
    	refresh
    	;;

    -b | brightness)
    
        CID=$SCLR
    	BRI="$2"

      if [[ "$BRI" == "+" ]]; then

              LEV=$(cat $CURRENT_BRI 2>/dev/null || echo 50)
              NEW=$((LEV + 10))
              if (( NEW > 100 )); then
              NEW=100
              fi
              echo "$NEW" > "$CURRENT_BRI"
              echo "Brightness set to ${NEW}"
              refresh
              exit 0
      elif [[ "$BRI" == "-" ]]; then
              LEV=$(cat $CURRENT_BRI 2>/dev/null || echo 50)
              NEW=$((LEV - 10))
                  if (( NEW < 0 )); then
                    NEW=10
                  fi

              echo "$NEW" > "$CURRENT_BRI"
              echo "Brightness Set: ${NEW}"
              refresh
              exit 0

      elif [[ "$BRI" =~ ^[0-9]+$ ]]; then

              echo "$BRI" > $CURRENT_BRI
              echo "Brigtness Set: $BRI"
              refresh
              exit 0
      else
              echo "Brigtness: $(cat $CURRENT_BRI)"
              refresh
              exit 0
      fi
      ;;

    -n | next)

        CID=$SCLR

          if [ ! -f "$CTR" ]; then
              echo 0 > "$CTR"
          fi

          LINE_NR=$(cat "$CTR")
          NEXT_LINE=$((LINE_NR + 1))
          LINE=$(sed -n "${NEXT_LINE}p" "$COLOR")

          if [ -z "$LINE" ]; then
              echo "None left"
              echo 0 > "$CTR"
              exit 1
          fi

            echo "Line: $LINE"
            echo "$NEXT_LINE" > "$CTR"
            echo "$LINE" > "$CURRENT_CLR"
            refresh
            ;;

    -p | previous)

        CID=$SCLR

          if [ ! -f "$CTR" ]; then
              echo 0 > "$CTR"
          fi

          LINE_NR=$(cat "$CTR")
          NEXT_LINE=$((LINE_NR - 1))
          LINE=$(sed -n "${NEXT_LINE}p" "$COLOR")

          if [ -z "$LINE" ]; then
              echo "None left."
              echo 0 > "$CTR"
              exit 1
          fi

          echo "Line Saved: $LINE"
          echo "$NEXT_LINE" > "$CTR"
          echo "$LINE" > "$CURRENT_CLR"
          refresh
          ;;
      *)
        help
        exit 0
        ;;
esac




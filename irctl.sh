#!/bin/bash

PREFIX="$HOME/Scripts"
echo "Starting ir watcher"

irw | while read -r line; do

    key=$(echo "$line" | awk '{print $3}')
    case "$key" in

        KEY_OK)
		echo "Turning leds on"
            	${PREFIX}/ledctl.sh on
	    	;;

        KEY_UP)
		echo "Brightness up +10"
           	${PREFIX}/ledctl.sh -b +
	    	;;

        KEY_DOWN)
		echo "Brightness down -10"
	    	${PREFIX}/ledctl.sh -b -
            	;;

        KEY_CANCEL)
		echo "Turning leds off"
		${PREFIX}/ledctl.sh off
		;; 

	KEY_RED)
		echo "Set RED"
		${PREFIX}/ledctl.sh red
		;;

	KEY_GREEN)
		echo "Set GREEN"
		${PREFIX}/ledctl.sh grn
		;;

	KEY_BLUE)
		echo "Set BLUE"
		${PREFIX}/ledctl.sh blu
		;;

	KEY_HOME)
		echo "Set White"
		${PREFIX}/ledctl.sh -s ffffff 100
		;;

	KEY_MODE)
		#${PREFIX}/ledctl.sh sensor
		;;

	KEY_OPTION)
		echo "OPTION"
		;;

	KEY_NEXT)
		${PREFIX}/ledctl.sh -n
		;;

	KEY_PREVIOUS)
		${PREFIX}/ledctl.sh -p
		;;

	KEY_A)
		;;

	KEY_B)
		;;

	KEY_0)
		;;

	KEY_1)
		;;

	KEY_2)
		;;

	KEY_3)
		;;

	KEY_4)
		;;

	KEY_5)
		;;

	KEY_6)
		;;

	KEY_7)
		;;

	KEY_8)
		;;

	KEY_9)
		;;

	*)
            echo "Unknown: $key"
            ;;
    esac
done

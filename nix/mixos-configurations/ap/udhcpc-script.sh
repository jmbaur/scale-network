# shellcheck shell=sh

# Take options ascii options and convert to strings
opt224=$(printf "%b\n" "$(echo $opt224 | sed 's/\(..\)/\\x\1/g')")
opt225=$(printf "%b\n" "$(echo $opt225 | sed 's/\(..\)/\\x\1/g')")
opt226=$(printf "%b\n" "$(echo $opt226 | sed 's/\(..\)/\\x\1/g')")

# Since this is called from other udhcpc scripts this cannot be changed to
# use /bin/bash without also modifying the script that calls this.

# TODO(jared): uncomment all instances of wlan1 stuff, when it works
# TODO(jared): replacement for "wifi" command
# TODO(jared): what does config-version.sh do?

case "$1" in
# Same actions for renew or bound for the time being
"renew" | "bound")
	# dump params to tmp so its easier to troubleshoot
	set >/tmp/dhcp.params

	wlan0_status=$(hostapd_cli -i wlan0 status)
	# wlan1_status=$(hostapd_cli -i wlan1 status)

	if echo "$wlan0_status" | grep -q "state=DISABLED"; then
		wlan0="off"
	else
		wlan0=$(echo "$wlan0_status" | grep "^channel=" | cut -d"=" -f2)
	fi

	# if echo "$wlan1_status" | grep -q "state=DISABLED"; then
	# 	wlan1="off"
	# else
	# 	wlan1=$(echo "$wlan1_status" | grep "^channel=" | cut -d"=" -f2)
	# fi

	if [[ ! -z "$opt224" ]] && [[ ! -z "$opt225" ]]; then
		if [[ "$opt224" != "$wlan0" ]] || [[ "$opt225" != "$radio1" ]]; then
			if [[ "$(echo $opt224 | tr '[A-Z]' '[a-z]')" != "off" ]]; then
				logger -t "dhcp-wifi" "changed wlan0 from $wlan0 to $opt224"
				hostapd_cli -i wlan0 set channel "$opt224"
				hostapd_cli -i wlan0 enable
			else
				hostapd_cli -i wlan0 disable
			fi

			if [[ "$(echo $opt225 | tr '[A-Z]' '[a-z]')" != "off" ]]; then
				true
				# logger -t "dhcp-wifi" "changed wlan1 from $wlan1 to $opt225"
				# hostapd_cli -i wlan1 set channel "$opt225"
				# hostapd_cli -i wlan1 enable
			else
				true
				# hostapd_cli -i wlan1 disable
			fi
		fi
	fi

	# apinger template population
	if [ ! -z "$router" ]; then
		sed "s/<DEFAULTGATEWAY>/${1}/g" /etc/apinger.tmpl >/tmp/apinger.conf
		# Only restart apinger if compare has diff
		if ! cmp /tmp/apinger.conf /etc/apinger.conf; then
			sleep 5
			# Make sure wifi always starts up since apinger will not trigger an alarm
			# if it pings good but wifi was down to begin with
			wifi up
			install -m0644 /tmp/apinger.conf /etc/apinger.conf
			pkill -1 apinger # SIGHUP to apinger reloads configuration
		fi
	fi

	if [[ ! -z "$hostname" ]]; then
		current_hostname=$(hostname)
		hostname "$hostname"
		logger -t "dhcp-hostname" "changed hostname from $current_hostname to $hostname"
		# TODO(jared): ask why this is needed
		# # reload/restart whatever needs the hostname updated
		# /etc/init.d/system reload
		# service rsyslog restart
		# service lldpd restart
		# # prometheus doesnt understand restart
		# service prometheus-node-exporter-lua stop
		# service prometheus-node-exporter-lua start
	fi
	if [ ! -z "$opt226" ]; then
		true
		# /root/bin/config-version.sh -c $opt226
	fi
	;;
esac

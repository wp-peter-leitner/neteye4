#!/usr/bin/env bash
#
# Copyright (C) 2012-2018 Icinga Development Team (https://icinga.com/)
# Except of function urlencode which is Copyright (C) by Brian White (brian@aljex.com) used under MIT license

PROG="`basename $0`"
ICINGA2HOST="`hostname`"
SMSBIN="smssend"

if [ -z "`which $SMSBIN`" ] ; then
  echo "$SMSBIN not found in \$PATH. Consider installing it."
  exit 1
fi

## Function helpers
Usage() {
cat << EOF

Required parameters:
  -d LONGDATETIME (\$icinga.long_date_time\$)
  -l HOSTNAME (\$host.name\$)
  -n HOSTDISPLAYNAME (\$host.display_name\$)
  -o HOSTOUTPUT (\$host.output\$)
  -r USERMOBILE (\$user.mobile\$)
  -s HOSTSTATE (\$host.state\$)
  -t NOTIFICATIONTYPE (\$notification.type\$)

Optional parameters:
  -4 HOSTADDRESS (\$address\$)
  -6 HOSTADDRESS6 (\$address6\$)
  -b NOTIFICATIONAUTHORNAME (\$notification.author\$)
  -c NOTIFICATIONCOMMENT (\$notification.comment\$)
  -i ICINGAWEB2URL (\$notification_icingaweb2url\$, Default: unset)
  -f MAILFROM (\$notification_mailfrom\$, requires GNU mailutils (Debian/Ubuntu) or mailx (RHEL/SUSE))
  -v (\$notification_sendtosyslog\$, Default: false)

EOF
}

Help() {
  Usage;
  exit 0;
}

Error() {
  if [ "$1" ]; then
    echo $1
  fi
  Usage;
  exit 1;
}

urlencode() {
  local LANG=C i c e=''
  for ((i=0;i<${#1};i++)); do
    c=${1:$i:1}
    [[ "$c" =~ [a-zA-Z0-9\.\~\_\-] ]] || printf -v c '%%%02X' "'$c"
    e+="$c"
  done
  echo "$e"
}

## Main
while getopts 4:6::b:c:d:f:hi:l:n:o:r:s:t:v: opt
do
  case "$opt" in
    4) HOSTADDRESS=$OPTARG ;;
    6) HOSTADDRESS6=$OPTARG ;;
    b) NOTIFICATIONAUTHORNAME=$OPTARG ;;
    c) NOTIFICATIONCOMMENT=$OPTARG ;;
    d) LONGDATETIME=$OPTARG ;; # required
    f) MAILFROM=$OPTARG ;;
    h) Help ;;
    i) ICINGAWEB2URL=$OPTARG ;;
    l) HOSTNAME=$OPTARG ;; # required
    n) HOSTDISPLAYNAME=$OPTARG ;; # required
    o) HOSTOUTPUT=$OPTARG ;; # required
    r) USERMOBILE=$OPTARG ;; # required
    s) HOSTSTATE=$OPTARG ;; # required
    t) NOTIFICATIONTYPE=$OPTARG ;; # required
    v) VERBOSE=$OPTARG ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Error ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Error ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Error ;;
  esac
done

shift $((OPTIND - 1))

## Keep formatting in sync with mail-service-notification.sh
for P in LONGDATETIME HOSTNAME HOSTDISPLAYNAME HOSTOUTPUT HOSTSTATE USERMOBILE NOTIFICATIONTYPE ; do
        eval "PAR=\$${P}"

        if [ ! "$PAR" ] ; then
                Error "Required parameter '$P' is missing."
        fi
done

## Build the message's subject
SUBJECT="NetEye [$NOTIFICATIONTYPE] Host $HOSTDISPLAYNAME is $HOSTSTATE!"

## Build the notification message
NOW=$(date +%H:%M" "%d-%b-%Y)
NOTIFICATION_MESSAGE="When: $NOW  Value: $HOSTOUTPUT"

## Check whether IPv4 was specified.
if [ -n "$HOSTADDRESS" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
IPv4:    $HOSTADDRESS"
fi

## Check whether IPv6 was specified.
if [ -n "$HOSTADDRESS6" ] ; then
  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
IPv6:    $HOSTADDRESS6"
fi

### Check whether author and comment was specified.
#if [ -n "$NOTIFICATIONCOMMENT" ] ; then
#  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
#
#Comment by $NOTIFICATIONAUTHORNAME:
#  $NOTIFICATIONCOMMENT"
#fi

### Check whether Icinga Web 2 URL was specified.
#if [ -n "$ICINGAWEB2URL" ] ; then
#  NOTIFICATION_MESSAGE="$NOTIFICATION_MESSAGE
#
#$ICINGAWEB2URL/monitoring/host/show?host=$(urlencode "$HOSTNAME")"
#fi

## Check whether verbose mode was enabled and log to syslog.
if [ "$VERBOSE" == "true" ] ; then
  logger "$PROG sends $SUBJECT => $USERMOBILE"
fi

## Send the mail using the $SMSBIN command.
## If an explicit sender was specified, try to set it.
#if [ -n "$MAILFROM" ] ; then
#
#  ## Modify this for your own needs!
#
#  ## Debian/Ubuntu use mailutils which requires `-a` to append the header
#  if [ -f /etc/debian_version ]; then
#    /usr/bin/printf "%b" "$NOTIFICATION_MESSAGE" | $SMSBIN -a "From: $MAILFROM" -s "$SUBJECT" $USERMOBILE
#  ## Other distributions (RHEL/SUSE/etc.) prefer mailx which sets a sender address with `-r`
#  else
#    /usr/bin/printf "%b" "$NOTIFICATION_MESSAGE" | $SMSBIN -r "$MAILFROM" -s "$SUBJECT" $USERMOBILE
#  fi
#
#else
  #/usr/bin/printf "%b" "$NOTIFICATION_MESSAGE"  | $SMSBIN $USERMOBILE "$SUBJECT"
  # modificato da VALU - 25-06-2019 ###
/usr/bin/printf "%b" " "  | $SMSBIN $USERMOBILE "$SUBJECT $NOTIFICATION_MESSAGE"
#fi
# copia i messaggi in un file di log - LV 21-06-2019-
 /usr/bin/printf "%b" "$SUBJECT $USERMOBILE $NOTIFICATION_MESSAGE \n \n" >> /tmp/sms-temp.log

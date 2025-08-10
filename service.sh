#!/system/bin/sh
MODDIR=${0%/*}
mv -f /system/addon.d /system/$(( RANDOM % 1000 ))
. "$MODDIR/momohide.sh" &
TMPPROP="$(magisk --path)/riru.prop"
MIRRORPROP="$(magisk --path)/.magisk/modules/riru-core/module.prop"
sh -Cc "cat '$MODDIR/module.prop' > '$TMPPROP'"
if [ $? -eq 0 ]; then
  mount --bind "$TMPPROP" "$MIRRORPROP"
  sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ⛔ post-fs-data.sh fails to run. Magisk is broken on this device. ] /g' "$MODDIR/module.prop"
  exit
fi

if mountpoint -q /cache; then
    logcat=/cache/riru_master.log
else
    logcat=/data/cache/riru_master.log
fi 
rm -rf ${logcat}.bak
mv -f $logcat ${logcat}.bak
logcat Riru:I *:S >>$logcat &
logcat MomoHider:I *:S >>$logcat &

MAGISKDIR="$(magisk --path)"
[ -z "$MAGISKDIR" ] && MAGISKDIR=/sbin

# wait device to boot completed
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done

# hide userdebug props

for propfile in /default.prop /system/build.prop /vendor/build.prop /product/build.prop /vendor/odm/etc/build.prop; do
    cat $propfile |  grep "^ro." | grep userdebug >>"$MAGISKDIR/.magisk/hide-userdebug.prop"
    cat $propfile |  grep "^ro." | grep test-keys >>"$MAGISKDIR/.magisk/hide-userdebug.prop"
done
sed -i "s/userdebug/user/g" "$MAGISKDIR/.magisk/hide-userdebug.prop"
sed -i "s/test-keys/release-keys/g" "$MAGISKDIR/.magisk/hide-userdebug.prop"
resetprop --file "$MAGISKDIR/.magisk/hide-userdebug.prop"

# hide usb debugging
{
    while true; do
        resetprop -n init.svc.adbd stopped
        sleep 1;
    done
} &


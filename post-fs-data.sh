#!/system/bin/sh
MODDIR=${0%/*}
TMPPROP="$(magisk --path)/riru.prop"
MIRRORPROP="$(magisk --path)/.magisk/modules/riru-core/module.prop"
sh -Cc "cat '$MODDIR/module.prop' > '$TMPPROP'"
if [ $? -ne 0 ]; then
  exit
fi
mount --bind "$TMPPROP" "$MIRRORPROP"
if [ "$ZYGISK_ENABLE" = "1" ]; then
    sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ⛔ Riru is not loaded because of Zygisk. ] /g' "$MIRRORPROP"
    exit
fi
sed -Ei 's/^description=(\[.*][[:space:]]*)?/description=[ ⛔ app_process fails to run. ] /g' "$MIRRORPROP"
cd "$MODDIR" || exit
flock "module.prop"
mount --bind "$TMPPROP" "$MODDIR/module.prop"
unshare -m sh -c "/system/bin/app_process -Djava.class.path=rirud.apk /system/bin --nice-name=rirud riru.Daemon $(magisk -V) $(magisk --path) $(getprop ro.dalvik.vm.native.bridge)&"
umount "$MODDIR/module.prop"


DATA_DIR="$MODDIR/config"
mkdir -p "$DATA_DIR"
MAGISK_TMP=$(magisk --path) || MAGISK_TMP="/sbin"
echo -n "$MAGISK_TMP" > "$DATA_DIR/magisk_tmp"
# enable momohider
echo -n > "$DATA_DIR/isolated"
echo -n > "$DATA_DIR/app_zygote_magic"
echo -n > "$DATA_DIR/setns"
echo -n > "$DATA_DIR/initrc"
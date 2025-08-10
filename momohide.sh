#!/system/bin/sh
MODDIR="${0%/*}"
rm -rf "$MODDIR/target"
## hidelist for momohider
{ while true; do
       HIDELIST="$(magisk --sqlite "SELECT process FROM hidelist" | sed "s/^process=//g")"
       rm -rf "$MODDIR/target.tmp"
       rm -rf "$MODDIR/target.old"
       mkdir "$MODDIR/target.tmp" 
       for process in $HIDELIST; do
          echo -n >"$MODDIR/target.tmp/$process"
       done
       mv -fT "$MODDIR/target" "$MODDIR/target.old"
       mv -fT "$MODDIR/target.tmp" "$MODDIR/target"
       rm -rf "$MODDIR/target.tmp"
       rm -rf "$MODDIR/target.old"
       sleep 3
done; } &
. "$MODDIR/props.sh"
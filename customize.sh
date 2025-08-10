SKIPUNZIP=1

RIRU_API="26"
RIRU_VERSION_CODE="534"
RIRU_VERSION_NAME="v26.1.7.r534.4c4695c65f"

if $BOOTMODE; then
  ui_print "- Installing from Magisk app"
else
  ui_print "*********************************************************"
  ui_print "! Install from recovery is NOT supported"
  ui_print "! Some recovery has broken implementations, install with such recovery will finally cause Riru or Riru modules not working"
  ui_print "! Please install from Magisk app"
  abort "*********************************************************"
fi

ui_print "- Installing Riru $RIRU_VERSION_NAME (Riru API $RIRU_API)"

# check Magisk
ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"

# check android
if [ "$API" -lt 23 ]; then
  ui_print "! Unsupported sdk: $API"
  abort "! Minimal supported sdk is 23 (Android 6.0)"
else
  ui_print "- Device sdk: $API"
fi

# check architecture
if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86" ] && [ "$ARCH" != "x64" ]; then
  abort "! Unsupported platform: $ARCH"
else
  ui_print "- Device platform: $ARCH"
fi

unzip -o "$ZIPFILE" 'verify.sh' -d "$TMPDIR" >&2
if [ ! -f "$TMPDIR/verify.sh" ]; then
  ui_print "*********************************************************"
  ui_print "! Unable to extract verify.sh!"
  ui_print "! This zip may be corrupted, please try downloading again"
  abort "*********************************************************"
fi
. $TMPDIR/verify.sh

extract "$ZIPFILE" 'customize.sh' "$TMPDIR/.vunzip"
extract "$ZIPFILE" 'verify.sh' "$TMPDIR/.vunzip"

ui_print "- Extracting Magisk files"

if [ "$MAGISK_VER_CODE" -ge 21000 ]; then
  MAGISK_CURRENT_MODULE_PATH=$(magisk --path)/.magisk/modules/riru-core
else
  MAGISK_CURRENT_MODULE_PATH=/sbin/.magisk/modules/riru-core
fi

extract "$ZIPFILE" 'module.prop' "$MODPATH"
cp "$MODPATH/module.prop" "$MODPATH/module.prop.bk"
extract "$ZIPFILE" 'post-fs-data.sh' "$MODPATH"
extract "$ZIPFILE" 'service.sh' "$MODPATH"
extract "$ZIPFILE" 'system.prop' "$MODPATH"
extract "$ZIPFILE" 'util_functions.sh' "$MODPATH"
extract "$ZIPFILE" 'uninstall.sh' "$MODPATH"

mkdir $MAGISK_CURRENT_MODULE_PATH
rm "$MAGISK_CURRENT_MODULE_PATH"/util_functions.sh
cp "$MODPATH"/util_functions.sh "$MAGISK_CURRENT_MODULE_PATH"/util_functions.sh

mkdir "$MODPATH/lib"
mkdir "$MODPATH/lib64"
mkdir "$MODPATH/system"
mkdir "$MODPATH/system/lib"
mkdir -p "$MODPATH/riru/lib"
[ "$IS64BIT" = true ] && mkdir "$MODPATH/system/lib64"

if [ "$ARCH" = "x86" ] || [ "$ARCH" = "x64" ]; then
  ui_print "- Extracting x86 libraries"
  extract "$ZIPFILE" 'lib/x86/libriru.so' "$MODPATH/lib" true
  extract "$ZIPFILE" 'lib/x86/libriruhide.so' "$MODPATH/lib" true
  extract "$ZIPFILE" 'lib/x86/libriruloader.so' "$MODPATH/system/lib" true
  extract "$ZIPFILE" 'riru_x86/lib/libmomohider.so' "$MODPATH/riru/lib" true
  

  if [ "$IS64BIT" = true ]; then
    ui_print "- Extracting x64 libraries"
    extract "$ZIPFILE" 'lib/x86_64/libriru.so' "$MODPATH/lib64" true
    extract "$ZIPFILE" 'lib/x86_64/libriruhide.so' "$MODPATH/lib64" true
    extract "$ZIPFILE" 'lib/x86_64/libriruloader.so' "$MODPATH/system/lib64" true
    mkdir -p "$MODPATH/riru/lib64"
    extract "$ZIPFILE" 'riru_x86/lib64/libmomohider.so' "$MODPATH/riru/lib64" true
    
  fi
else
  ui_print "- Extracting arm libraries"
  extract "$ZIPFILE" 'lib/armeabi-v7a/libriru.so' "$MODPATH/lib" true
  extract "$ZIPFILE" 'lib/armeabi-v7a/libriruhide.so' "$MODPATH/lib" true
  extract "$ZIPFILE" 'lib/armeabi-v7a/libriruloader.so' "$MODPATH/system/lib" true
  extract "$ZIPFILE" 'riru/lib/libmomohider.so' "$MODPATH/riru/lib" true

  if [ "$IS64BIT" = true ]; then
    ui_print "- Extracting arm64 libraries"
    extract "$ZIPFILE" 'lib/arm64-v8a/libriru.so' "$MODPATH/lib64" true
    extract "$ZIPFILE" 'lib/arm64-v8a/libriruhide.so' "$MODPATH/lib64" true
    extract "$ZIPFILE" 'lib/arm64-v8a/libriruloader.so' "$MODPATH/system/lib64" true
    mkdir -p "$MODPATH/riru/lib64"
    extract "$ZIPFILE" 'riru/lib64/libmomohider.so' "$MODPATH/riru/lib64" true
  fi
fi
    

extract "$ZIPFILE" 'sepolicy.rule' "$MODPATH" true
extract "$ZIPFILE" 'props.sh' "$MODPATH" true
extract "$ZIPFILE" 'momohide.sh' "$MODPATH" true

ui_print "- Setting permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644

ui_print "- Extracting rirud"
extract "$ZIPFILE" "rirud.apk" "$MODPATH"
set_perm "$MODPATH/rirud.apk" 0 0 0600

ui_print "- Checking if your ROM has incorrect SELinux rules"
/system/bin/app_process -Djava.class.path="$MODPATH/rirud.apk" /system/bin --nice-name=riru_installer riru.Installer --check-selinux

ui_print "- Removing old files"
rm -rf /data/adb/riru/bin
rm /data/adb/riru/native_bridge
rm /data/adb/riru/api_version.new
rm /data/adb/riru/version_code.new
rm /data/adb/riru/version_name.new
rm /data/adb/riru/enable_hide
rm /data/adb/riru/api_version
rm /data/adb/riru/util_functions.sh
rm /data/misc/riru/api_version
rm /data/misc/riru/version_code
rm /data/misc/riru/version_name

# If Huawei's Maple is enabled, system_server is created with a special way which is out of Riru's control
HUAWEI_MAPLE_ENABLED=$(grep_prop ro.maple.enable)
if [ $HUAWEI_MAPLE_ENABLED == "1" ]; then
  ui_print "- Add ro.maple.enable=0"
  echo "ro.maple.enable=0" >> "$MODPATH/system.prop"
fi
mask_lib() {

  # Real /system can be found here.
  #
  MAGISKPATH=$(magisk --path)

  local mirror=/$MAGISKPATH/.magisk/mirror
  local so=liboemcrypto.so

  for part in system vendor; do
    for libdir in lib lib64; do
      if [ -s $mirror/$part/$libdir/$so ]; then
	size=$(ls -l $mirror/$part/$libdir/$so | awk '{print $5}')
        ui_print "- Delete: /$part/$libdir/$so"
	if [ $part = vendor ]; then
	  instdir=system/vendor
	else
	  instdir=$part
	fi

	mkdir -p $MODPATH/$instdir/$libdir 2>/dev/null
	ln -s /xxxxx $MODPATH/$instdir/$libdir/$so
      fi
    done
  done
}

warn_if_superfluous() {

  bl=$(getprop ro.boot.bootloader)

  # Device is either 4 or 5 characters long, depending on length of
  # bootloader string.
  #
  device=${bl:0:$((${#bl} - 8))}

  if ( [ $device = G975F ] || [ $device = G973F ] || [ $device = G970F ]); then
    ui_print "- Warning: This module is not needed on the $device."
    ui_print ''
  fi
}

warn_if_superfluous
mask_lib

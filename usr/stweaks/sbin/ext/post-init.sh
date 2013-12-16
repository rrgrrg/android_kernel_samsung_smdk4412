#!/system/bin/sh

# Detect Boot Failure
if [ -f /data/check ];then
  rm /data/check
  rm /data/system/default.profile
fi

echo "test" > /data/check
chmod 777 /data/check

# liblights install by force to allow BLN
mount -o rw,remount /system
cp -a /res/lights.exynos4.so /system/lib/hw/lights.exynos4.so;
chown root:root /system/lib/hw/lights.exynos4.so;
chmod 644 /system/lib/hw/lights.exynos4.so;
mount -o ro,remount /system

# Remove old STweaks
if [ -f /data/app/com.gokhanmoral.stweaks.* ];then
  rm /data/app/com.gokhanmoral.stweaks.*
fi

# Install new STweaks
if [ ! -f /system/app/STweaks.apk ];then
  mount -o rw,remount /system
  cp /res/STweaks.apk /system/app/STweaks.apk
  chmod 644 /system/app/STweaks.apk
  mount -o ro,remount /system
fi

. /res/customconfig/customconfig-helper

ccxmlsum=`md5sum /res/customconfig/customconfig.xml | awk '{print $1}'`
if [ -f /data/system/.ccxmlsum ];then
  if [ "a${ccxmlsum}" != "a`cat /data/system/.ccxmlsum`" ];
  then
    rm /data/system/default.profile
    echo ${ccxmlsum} > /data/system/.ccxmlsum
  fi
else
  echo ${ccxmlsum} > /data/system/.ccxmlsum
fi

read_defaults
read_config

# Enable Haveged Entropy Tweaks
if [ "$frandom" == "on" ];then
  if [ ! -f /system/xbin/haveged ];then
    mount -o remount,rw /system
    cat /res/haveged > /system/xbin/haveged
    chown root.root /system/xbin/haveged
    chmod 0755 /system/xbin/haveged
    mount -o remount,ro /system
  fi
  . /sbin/ext/haveged.sh
fi

# Disable Haveged Entropy Tweaks
if [ "$frandom" == "off" ];then
  if [ -f /system/xbin/haveged ];then
    mount -o remount,rw /system
    rm /system/xbin/haveged
    mount -o remount,ro /system
  fi
fi

# disable debugging on some modules
if [ "$logger" == "off" ];then
  echo "0" > /sys/module/ump/parameters/ump_debug_level;
  echo "0" > /sys/module/mali/parameters/mali_debug_level;
  echo "0" > /sys/module/kernel/parameters/initcall_debug;
  echo "0" > /sys/module/lowmemorykiller/parameters/debug_level;
  echo "0" > /sys/module/cpuidle_exynos4/parameters/log_en;
  echo "0" > /sys/module/earlysuspend/parameters/debug_mask;
  echo "0" > /sys/module/alarm/parameters/debug_mask;
  echo "0" > /sys/module/alarm_dev/parameters/debug_mask;
  echo "0" > /sys/module/binder/parameters/debug_mask;
  echo "0" > /sys/module/xt_qtaguid/parameters/debug_mask;
fi

# enable kmem interface for everyone
echo 0 > /proc/sys/kernel/kptr_restrict

# disable cpuidle log
echo 0 > /sys/module/cpuidle_exynos4/parameters/log_en

# apply STweaks defaults
export CONFIG_BOOTING=1
. /res/uci.sh apply
export CONFIG_BOOTING=

# Disables Built In Error Reporting
setprop profiler.force_disable_err_rpt 1
setprop profiler.force_disable_ulog 1

sleep 15
rm /data/check


#!/usr/bin/env bash

# Detect current OS for different tool sets.
case $OSTYPE in
    darwin*)
        os="macos"
        echo "Identified as an macOS platform."
        ;;
    linux*|bsd*)
        os="linux"
        echo "Identified as an *nix platform."
        ;;
    cygwin)
        echo "ERROR: Please use the .bat file instead of this .sh file."
        exit 1
        ;;
    *)
        echo "ERROR: Unable to identify the operating system."
        exit 1
        ;;
esac
echo

add_path() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1${PATH:+":$PATH"}"
    fi
}

# Use bundled tools.
tool_dir=$(pwd)/tools/${os}
add_path ${tool_dir}/jre/bin
add_path ${tool_dir}/platform-tools
# Set common tools.
apktool=$(pwd)/tools/common/apktool.jar
signapk=$(pwd)/tools/common/sign.jar

echo "Please plug in your device and allow the USB debugging request..."
adb wait-for-usb-device > /dev/null 2>&1

manuf=$(adb -d shell getprop ro.product.manufacturer | tr -dc '[:alnum:]')
model=$(adb -d shell getprop ro.product.model | tr -dc '[:alnum:]')
echo "... Detected! Proceed with ${manuf} ${model}."
echo

# Ask for target package.
#echo "===================="
#adb shell pm list packages | sed -e "s/^package://"
#echo "===================="
#printf "Please choose a package name from the list above: "
#read pkg_name
#echo
pkg_name="jp.naver.line.android"
pkg_path=$(adb -d shell pm path ${pkg_name} | tr -d '[:cntrl:]' | sed -e "s/^package://")

echo "Target package is \"${pkg_name}\", start pulling..."
adb -d pull ${pkg_path} ${pkg_name}.apk
echo

echo "Analyzing the package..."
java -jar ${apktool} d ${pkg_name}.apk -f -o decoded
manif=decoded/AndroidManifest.xml
if grep -Fq 'android:allowBackup="false"' ${manif} ; then
    echo "Attribute 'allowBackup=\"false\"' found! Modify it to \"true\"."
    sed -i.bak 's#android:allowBackup="false"#android:allowBackup="true"#g' "${manif}"

    echo "Rebuilding the package..."
    java -jar ${apktool} b decoded -o ${pkg_name}.rebuilt.apk

    echo "Signing the package..."
    java -jar ${signapk} ${pkg_name}.rebuilt.apk --override

    echo "Pushing the rebuilt package to device..."
    adb -d install -r ${pkg_name}.rebuilt.apk
else
    echo "No need to modify the package."
fi
echo

# Prompt to rename if old backup file was found.
if [ -f *.ab ] ; then
    echo "ERROR: Residual backup file .ab found!"
else
    adb -d backup ${pkg_name} -f pkg_bak.ab
    echo "(Please do not setup a password.)"
fi
echo

## Force reinstallation. Uninstall the app and redirect to the Google Play Store.
#echo "Uninstalling the modified package..."
#adb -d uninstall ${pkg_name}
#echo "Please reinstall the package through Google Play Store"
#adb shell am start -a android.intent.action.VIEW -d 'market://details?id=${pkg_name}'
#echo

# Pull the newly installed app.

# Modify the flag again.

# Install the modified app.

# Restore the data.

# Restore the newly installed app.

if [ -f ${pkg_name}.rebuilt.apk ] ; then
    echo "Restoring the original package."
    adb -d install -r ${pkg_name}.apk
fi

echo "Removing intermediate files and packages..."
rm -rf decoded
rm -f *.apk 2> /dev/null

adb kill-server
echo "ADB server stopped."

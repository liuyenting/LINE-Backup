# LINE Backup
A simple backup script that modify the LINE apk file on-the-fly to enable system backup.

## Pre-requisite
- Please download and place JRE from Oracle under the `tools/<platform>/jre` directory for each platform.
- Ensure you have enabled debugging in the developer options.
- For Windows user, [Cygwin](https://www.cygwin.com/) is required to run the shell script!

## Quick start
Start the script by `./force_backup.sh` and follow the on-screen instruction.
On some system, `root` permission is required for `adb` debug bridge, use with _cautions_!

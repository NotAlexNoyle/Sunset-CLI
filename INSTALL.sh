#!/bin/bash

# Greeter
echo
echo "Welcome to Sunset by NotAlexNoyle."
echo
echo "This patch enables Night Shift functionality on macOS 10.12.4 and later for Macs that apple isn't officially supporting."
echo
# TODO: Make "To continue, give the script permission..." line only show up when a password is actually required.
# TIP: When sudo --validate is run the SECOND time, there is no password prompt.
#if [[  ]]; then
	echo "To continue, give the script permission to modify system files."
#fi

# Logs in as root
sudo --validate
echo
# Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [[ "$(csrutil status)" == "System Integrity Protection status: enabled." ]]; then

	echo "ERROR: System Integrity Protection is enabled. This patch requires disabling it to operate properly. After the patch is complete, you may re-enable System Integrity Protection. Learn more: https://bit.ly/2BNgiVP"

else

	isPatchedFrameworkAlreadyInstalled=$(/usr/bin/osascript -e '

		set pathToTest to "/System/Library/PrivateFrameworks/CoreBrightness.framework/Versions/A/Teller.txt"

		tell application "Finder"

			if exists pathToTest as POSIX file then

				return 1

			end if

		end tell

	')

	if [[ "$isPatchedFrameworkAlreadyInstalled" == "1" ]]; then

		echo "ERROR: The patched framework is already installed. To reinstall, run UNINSTALL.sh, reboot your Mac, then run this script again."

	else
		# Fetches CoreBrightness.framework backup directory for current user
		doesLocalBackupExist=$(/usr/bin/osascript -e '

			set userHomePath to get the path to home folder as string

			set userHomePathInPOSIXFormat to POSIX path of userHomePath

			set finalPath to userHomePathInPOSIXFormat & "CoreBrightness-Backup/CoreBrightness.framework"

			tell application "Finder"
			
				if exists finalPath as POSIX file then
				
					return 1

				end if

			end tell

		')

		if [[ "$doesLocalBackupExist" == "1" ]]; then
			read -p "A backup of your settings was already found in ~/CoreBrightness-Backup/. Would you like to use this backup (Y), or create a new one based on your current configuration? (N)"
			# Yes acceptor
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				echo "Using existing backup..."
				echo
			fi
		else
			echo "Backing up the original framework..."
			echo
			mkdir ~/CoreBrightness-Backup/
			sudo cp -R /System/Library/PrivateFrameworks/CoreBrightness.framework ~/CoreBrightness-Backup/CoreBrightness.framework
			
			echo "Deleting original framework... (copy in ~/CoreBrightness-Backup/)"
			echo
			sudo rm -rf /System/Library/PrivateFrameworks/CoreBrightness.framework/

			echo "Enabling the patched framework..."
			echo
			sudo cp -R PatchedCoreBrightness.framework /System/Library/PrivateFrameworks/CoreBrightness.framework

			echo "Fixing permissions and signing patched framework..."
			echo
			sudo chmod -R 755 /System/Library/PrivateFrameworks/CoreBrightness.framework
			sudo chown -R 0:0 /System/Library/PrivateFrameworks/CoreBrightness.framework

			# Signs the patched framework
			sudo codesign -f -s - /System/Library/PrivateFrameworks/CoreBrightness.framework/Versions/A/CoreBrightness > /dev/null 2>&1
			echo "Done. Reboot your Mac to complete the patching process."
			echo "Special thanks to Isiah Johnson (TMRJIJ) for his helpful open source code."
			echo "Credit to dosdude1 for the modified CoreBrightness.framework."
		fi
	fi

fi
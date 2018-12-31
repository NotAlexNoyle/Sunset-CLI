#!/bin/bash

# TODO: Add user intro prompt explaining and crediting for the script. Collect password at this (first) prompt.

if [[ "$(csrutil status)" == "System Integrity Protection status: enabled." ]]; then

	echo "ERROR: System Integrity Protection is enabled. This patch requires disabling it to operate properly. After the patch is complete, you may re-enable System Integrity Protection. Learn more: https://bit.ly/2BNgiVP"

else

	echo "Searching for original framework backup..."
	echo

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
		echo "Framework backup found. Proceeding to uninstallation..."
		echo

		echo "Removing patched framework..."
		echo
		sudo rm -rf /System/Library/PrivateFrameworks/CoreBrightness.framework

		echo "Restoring original framework..."
		echo
		sudo cp -R ~/CoreBrightness-Backup/CoreBrightness.framework /System/Library/PrivateFrameworks/CoreBrightness.framework

		echo "Signing original framework..."
		echo
		sudo codesign -f -s - /System/Library/PrivateFrameworks/CoreBrightness.framework/Versions/A/CoreBrightness > /dev/null 2>&1

		# Clean up backup directory that's no longer needed
		echo "Cleaning up..."
		echo
		sudo rm -rf ~/CoreBrightness-Backup/
		echo "Reverted to stock functionality successfully. Reboot your Mac to complete."
	else
		read -p "Your framework backup could not be found. Would you like to attempt restoring stock functionality using a generic framework from the macOS 10.13.6 installer? Otherwise, the uninstaller will quit. (Y/N) " -n 1 -r
		echo
		# "Yes acceptor
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo "Now utilizing generic framework."
			echo

			echo "Removing patched framework..."
			echo
			sudo rm -rf /System/Library/PrivateFrameworks/CoreBrightness.framework

			echo "Restoring from generic framework..."
			echo
			sudo cp -R LastResort.framework /System/Library/PrivateFrameworks/CoreBrightness.framework

			echo "Signing generic framework..."
			echo
			sudo codesign -f -s - /System/Library/PrivateFrameworks/CoreBrightness.framework/Versions/A/CoreBrightness > /dev/null 2>&1

			# Clean up backup directory that's no longer needed
			echo "Cleaning up..."
			echo
			rm -rf ~/CoreBrightness-Backup/ 
			echo "Done. Reboot your Mac to test whether or not stock functionality has been successfully restored."
		else
			echo "Goodbye."
		fi
	fi

fi

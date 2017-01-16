#!/bin/sh
# Xcode Auto Increment Buildnumber Script

echo "BundleVersion and Date script"
buildPlist=${PROJECT_DIR}/${INFOPLIST_FILE}

# get the buildnumber
CFBuildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" $buildPlist)
# increment with 1
CFBuildNumber=$(($CFBuildNumber + 1))
# set builddate to 'now'
CFBuildDate=$(date -u +"%a %b %d %T GMT %Y")

# update the properties for your <project>-Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CFBundleVersion" $buildPlist
/usr/libexec/PlistBuddy -c "Set :CFBuildDate $CFBuildDate" $buildPlist
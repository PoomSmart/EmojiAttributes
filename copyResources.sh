#!/usr/bin/env bash
# Unnecessary as of iOS 10

if [ -z $1 ];then
  echo "Runtime version required"
  exit 1
fi

EA_RUNTIME_ROOT=/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ ${1}.simruntime/Contents/Resources/RuntimeRoot
EA_BITMAP_NAME=emoji.bitmap

sudo cp -v "${PWD}/layout/System/Library/PrivateFrameworks/TextInput.framework/${EA_BITMAP_NAME}" "${EA_RUNTIME_ROOT}/System/Library/PrivateFrameworks/TextInput.framework/"

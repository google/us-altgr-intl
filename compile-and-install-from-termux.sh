#!/bin/sh
# Script to compile and install this package from a Termux session.

set -ex

mkdir -p bin gen obj
apt install aapt apksigner ecj4.6

aapt package \
	-f -m \
	-M AndroidManifest.xml \
	-S res/ \
	-F bin/USAltGrIntl-unsigned.apk \
	-J gen/

ecj \
	-d obj/ \
	-sourcepath src \
	$(find src -name \*.java)

dx --dex \
	--output=bin/classes.dex \
	obj/

(
	cd bin
	aapt add \
		-f USAltGrIntl-unsigned.apk \
		classes.dex
)

apksigner \
	.keystore \
	bin/USAltGrIntl-unsigned.apk \
	bin/USAltGrIntl-debug.apk

cp \
	bin/USAltGrIntl-debug.apk \
	/sdcard/Download/

am start \
	-d file:///sdcard/Download/USAltGrIntl-debug.apk

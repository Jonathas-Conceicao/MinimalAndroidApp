SHELL = /bin/bash

# Executables and files definitionos

ANDROID_HOME =/opt/Android
JAVA_HOME    =/usr/lib/jvm/java-1.8.0-openjdk

AAPT =$(ANDROID_HOME)/build-tools/android-9/aapt
ZIPA =$(ANDROID_HOME)/build-tools/android-9/zipalign
DX   =$(ANDROID_HOME)/build-tools/android-9/dx
APKS =$(ANDROID_HOME)/build-tools/android-9/apksigner
ANDROID_PLATFORM =$(ANDROID_HOME)/platforms/android-22/android.jar
KEY_FILE =keystore.jks

JC =javac
JFLAGS =-Xlint:all

SRC =src

RES =res

APK =build/apk
GEN =build/gen
OBJ =build/obj
APK_FILE=build/MinimalAndroidApp.apk
DEX_FILE=$(APK)/classes.dex

MANIFEST =AndroidManifest.xml
RES_FILE =$(GEN)/$(PACKAGE_PATH)/minimalandroidapp/R.java

# Constant package name
PACKAGE_PATH =br/edu/ufpel/inf/lups

# List of files (.java) to be compiled
FILES =minimalandroidapp/MainActivity

# Function for clean rule
define clean_regex
	find $(1) -name $(2) -exec rm {} \;
endef

CLS =$(addprefix $(OBJ)/$(PACKAGE_PATH)/, $(addsuffix .class, $(FILES))) 

.PHONY: all build clean
all: build

build: buildAPK

buildAPK: $(APK_FILE)

buildDEX: $(DEX_FILE)

buildCLS: $(CLS)

buildRES: $(RES_FILE)

$(APK_FILE): $(DEX_FILE)
	$(AAPT) package -f -M $(MANIFEST) -S $(RES) -I $(ANDROID_PLATFORM) -F $@.unsigned build/apk/
	$(ZIPA) -f -p 4 $@.unsigned $@.aligned
	$(APKS) sign --ks $(KEY_FILE) \
					--ks-key-alias androidkey --ks-pass pass:android --key-pass pass:android \
					--out $@ $@.aligned
	@rm -f $@.unsigned $@.aligned

$(DEX_FILE): $(CLS)
	@echo "Building $@"
	$(DX) --dex --output=$@ $(OBJ)

$(OBJ)/%.class: $(SRC)/%.java $(RES_FILE)
	@echo "Building $@ with $^"
	$(JC) $(JFLAGS) -cp $(ANDROID_PLATFORM) -d $(OBJ) $^

$(RES_FILE): $(shell find $(RES) -type f)
	$(AAPT) package -f -m -J $(GEN)/ -S $(RES) -M $(MANIFEST) -I $(ANDROID_PLATFORM)

clean:
	$(call clean_regex, build/, *.pkt)
	$(call clean_regex, build/, *.class)
	$(call clean_regex, build/, *.java)
	$(call clean_regex, build/, *.dex)
	$(call clean_regex, build/, *.apk)

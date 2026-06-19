IOS_VERSION = 18.5
TVOS_VERSION = 18.5
WATCHOS_VERSION = 11.5
OTHER_SWIFT_FLAGS="-DRESILIENT_LIBRARIES"
PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS $(IOS_VERSION),iPhone \d\+ Pro [^M])
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,id=$(call udid_for,tvOS $(TVOS_VERSION),TV)
PLATFORM_WATCHOS = watchOS Simulator,id=$(call udid_for,watchOS $(WATCHOS_VERSION),Watch)

TEST_RUNNER_CI = $(CI)

default: test

test: test-ios test-macos test-tvos test-watchos test-examples

test-ios: warm-simulator
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination platform="$(PLATFORM_IOS)"
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination platform="$(PLATFORM_IOS)"
test-macos: warm-simulator
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination platform="$(PLATFORM_MACOS)"
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination platform="$(PLATFORM_MACOS)"
test-tvos: warm-simulator
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination platform="$(PLATFORM_TVOS)"
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination platform="$(PLATFORM_TVOS)"
test-watchos: warm-simulator
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination platform="$(PLATFORM_WATCHOS)"
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination platform="$(PLATFORM_WATCHOS)"

test-examples: warm-simulator
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme CaseStudies \
		-destination platform="$(PLATFORM_IOS)"

build-for-library-evolution: warm-simulator
	swift build \
		-c release \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution \
		-Xswiftc $(OTHER_SWIFT_FLAGS)
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-destination platform="$(PLATFORM_IOS)" \
		-scheme SwiftNavigation \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		OTHER_SWIFT_FLAGS=$(OTHER_SWIFT_FLAGS)

DOC_WARNINGS := $(shell xcodebuild clean docbuild \
	-scheme SwiftUINavigation \
	-destination platform="$(PLATFORM_MACOS)" \
	-quiet \
	2>&1 \
	| grep "couldn't be resolved to known documentation" \
	| sed 's|$(PWD)|.|g' \
	| tr '\n' '\1')
test-docs:
	@test "$(DOC_WARNINGS)" = "" \
		|| (echo "xcodebuild docbuild failed:\n\n$(DOC_WARNINGS)" | tr '\1' '\n' \
		&& exit 1)

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		./Examples ./Package.swift ./Sources ./Tests

warm-simulator:
	@test "$(PLATFORM_IOS)" != "" \
		&& xcrun simctl boot $(PLATFORM_ID) \
		&& open -a Simulator --args -CurrentDeviceUDID $(PLATFORM_IOS) \
		|| exit 0

.PHONY: format test-all test-docs warm-simulator

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef

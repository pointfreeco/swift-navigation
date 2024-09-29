PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS 17.5,iPhone \d\+ Pro [^M])
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,id=$(call udid_for,tvOS 17.5,TV)
PLATFORM_WATCHOS = watchOS Simulator,id=$(call udid_for,watchOS 10.5,Watch)

TEST_RUNNER_CI = $(CI)

default: test

test: test-ios test-macos test-tvos test-watchos test-examples

test-ios:
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination platform="$(PLATFORM_IOS)"
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination platform="$(PLATFORM_IOS)"
test-macos:
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination platform="$(PLATFORM_MACOS)"
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination platform="$(PLATFORM_MACOS)"
test-tvos:
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination platform="$(PLATFORM_TVOS)"
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination platform="$(PLATFORM_TVOS)"
test-watchos:
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination platform="$(PLATFORM_WATCHOS)"
	xcodebuild build \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination platform="$(PLATFORM_WATCHOS)"

test-examples:
	xcodebuild test \
		-workspace SwiftNavigation.xcworkspace \
		-scheme CaseStudies \
		-destination platform="$(PLATFORM_IOS)"

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

.PHONY: format test-all test-docs

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef

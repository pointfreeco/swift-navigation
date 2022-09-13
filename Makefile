PLATFORM_IOS = iOS Simulator,name=iPhone 11 Pro Max
PLATFORM_MACOS = macOS
PLATFORM_TVOS = tvOS Simulator,name=Apple TV 4K (at 1080p)
PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 4 - 44mm

default: test

test:
	xcodebuild test \
		-workspace SwiftUINavigation.xcworkspace \
		-scheme SwiftUINavigation \
		-destination platform="$(PLATFORM_IOS)"
	xcodebuild test \
		-workspace SwiftUINavigation.xcworkspace \
		-scheme SwiftUINavigation \
		-destination platform="$(PLATFORM_MACOS)"
	xcodebuild test \
		-workspace SwiftUINavigation.xcworkspace \
		-scheme SwiftUINavigation \
		-destination platform="$(PLATFORM_TVOS)"
	xcodebuild \
		-workspace SwiftUINavigation.xcworkspace \
		-scheme SwiftUINavigation \
		-destination platform="$(PLATFORM_WATCHOS)"

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

OTHER_SWIFT_FLAGS="-DRESILIENT_LIBRARIES"
TEST_RUNNER_CI = $(CI)

default: test

test: test-ios test-macos test-tvos test-watchos test-examples

test-ios:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination $(call destination_ios)
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination $(call destination_ios)
test-macos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination $(call destination_macos)
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination $(call destination_macos)
test-tvos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination $(call destination_tvos) \
		-destination-timeout 120
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination $(call destination_tvos) \
		-destination-timeout 120
test-watchos:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftNavigation \
		-destination $(call destination_watchos)
	xcodebuild build \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme DynamicFramework \
		-destination $(call destination_watchos)

test-examples:
	xcodebuild test \
		-skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme CaseStudies \
		-destination $(call destination_ios)

DOC_WARNINGS := $(shell xcodebuild clean docbuild \
	-scheme SwiftUINavigation \
		-destination $(call destination_macos) \
	-quiet \
	2>&1 \
	| grep "couldn't be resolved to known documentation" \
	| sed 's|$(PWD)|.|g' \
	| tr '\n' '\1')
test-docs:
	@test "$(DOC_WARNINGS)" = "" \
		|| (echo "xcodebuild docbuild failed:\n\n$(DOC_WARNINGS)" | tr '\1' '\n' \
		&& exit 1)

library-evolution: build-for-library-evolution-ios build-for-library-evolution-macos

library-evolution-macos:
	swift build \
		-c release \
		--target SwiftUINavigation \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution \
		-Xswiftc $(OTHER_SWIFT_FLAGS)

	swift build \
		-c release \
		--target AppKitNavigation \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution \
		-Xswiftc $(OTHER_SWIFT_FLAGS)

library-evolution-ios:
	xcodebuild build \
	  -skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme SwiftUINavigation \
		-destination $(call destination_ios) \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		OTHER_SWIFT_FLAGS=$(OTHER_SWIFT_FLAGS)

	xcodebuild build \
	  -skipMacroValidation \
		-workspace SwiftNavigation.xcworkspace \
		-scheme UIKitNavigation \
		-destination $(call destination_ios) \
		BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
		OTHER_SWIFT_FLAGS=$(OTHER_SWIFT_FLAGS)

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--parallel \
		--recursive \
		./Examples ./Package.swift ./Sources ./Tests

.PHONY: format test-all test-docs

define destination_ios
"platform=iOS Simulator,name=iPhone 15 Pro Max,OS=$(IOS_VERSION)"
endef

define destination_watchos
"platform=watchOS Simulator,name=Apple Watch Series 6 (44mm),OS=$(WATCHOS_VERSION)"
endef

define destination_tvos
"platform=tvOS Simulator,name=Apple TV 4K (3rd Generation),OS=$(TVOS_VERSION)"
endef

define destination_macos
"platform=macOS"
endef

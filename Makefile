.PHONY: all build release install run clean

all: install run

build:
	swift build

release:
	swift build -c release

install: release
	@./build.sh

run: install
	@killall GeminiUsageBar 2>/dev/null || true
	@sleep 0.5
	@open /Applications/GeminiUsageBar.app
	@echo "✅ GeminiUsageBar launched from /Applications"

clean:
	swift package clean
	rm -rf .build

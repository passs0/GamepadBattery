.PHONY: all app run clean install

all: app

app:
	@chmod +x build.sh
	@./build.sh

run: app
	@open "build/Gamepad Battery.app"

clean:
	@rm -rf .build build

install: app
	@echo "Installing to /Applications..."
	@cp -R "build/Gamepad Battery.app" /Applications/
	@echo "Installed Gamepad Battery to /Applications"

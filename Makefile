build : protos src/Main.js
	cargo build

run : build
	cargo run

static/Main.js : elm/src/Main.elm
	mkdir -p static/
	cd elm && elm make src/Main.elm --output ../static/Main.js

protos :
	mkdir -p src/protobuf elm/protobuf
	protoc --rust_out src/protobuf/ --elm_out=elm/protobuf protobuf/*.proto
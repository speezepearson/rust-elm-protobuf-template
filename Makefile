build : protos src/Main.js
	cargo build

run : build
	cargo run

src/Main.js : elm/src/Main.elm
	cd elm && elm make src/Main.elm --output ../static/Main.js

protos :
	mkdir -p src/protobuf elm/protobuf
	protoc --rust_out src/protobuf/ --elm_out=elm/protobuf protobuf/*.proto
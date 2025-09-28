# Video Demo Client 
gRPC Video Demo


spec: SwiftUI, Combine, WebRTC, gRPC, Protobuf

server: https://github.com/decaf-hailey/VideoDemoServer
 
 
 
 # 1. execute server
  - git clone --branch 2.0.0 https://github.com/grpc/grpc-swift
  - $ cd Example/v1/HelloWorld
  - $ PROTOC_PATH=$(which protoc) swift run HelloWorldServer  - port 1234
   ## 1-1. server test
  - $ swift run HelloWorldClient {any name}
    Build of product 'HelloWorldClient' complete! (5.06s)
	Greeter received: Hello {name}!
	
	
 
 # 2. generate .proto
 // when you install $brew install protoc-gen-grpc-swift it automatically install protoc-gen-grpc-swift-2   
// on MyProject/
    - $ protoc --proto_path=protos signaling.proto \
               --swift_out=generated \
               --grpc-swift_out=Client=true,Server=false:generated \
               --plugin=protoc-gen-grpc-swift={My Homebrew Path}/protoc-gen-grpc-swift-2
               
               
               
            
            
            
### current issue:
 - can't compile 'NIOClientTransport : conflict dependency versions - grpc-swift & grpc-swift-nio-transport : gRPC Swift 2.0, GRPCCore, ClientConnection, ClientTransport ...

```
cd ./example/grpc
grpc_tools_ruby_protoc -I api --ruby_out=../lib --grpc_out=../lib api/hello_service.proto
```

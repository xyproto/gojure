# gojure

Run Clojure within Go, using github.com/zxh0/jvm.go

## WORK IN PROGRESS

`main.go` is from `jvm.go`

Zulu is a build of OpenJDK 8 from https://www.azulsystems.com/products/zulu/downloads, as [recommended by `jvm.go`](https://github.com/zxh0/jvm.go#run-jvmgo-using-zulu).

`Hello.class` was built with OpenJDK 13.0.2 with `javac Hello.java`.

* `go build` builds `gojure`.
* `./gojure Hello` executes `Hello.class` and outputs "Hello from Java from within Go".

Just running `./run.sh` is also possible.

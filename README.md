# gojure

The idea is to run Clojure within Go, using [zxh0/jvm.go](https://github.com/zxh0/jvm.go).

`main.go` is from [zxh0/jvm.go](https://github.com/zxh0/jvm.go) and only slightly modified.

Zulu is a build of OpenJDK 8 from https://www.azulsystems.com/products/zulu/downloads, as [recommended by `jvm.go`](https://github.com/zxh0/jvm.go#run-jvmgo-using-zulu).

`Hello.class` was built with OpenJDK 13.0.2 with `javac Hello.java`.

* `go build` builds `gojure`.
* `./gojure Hello` executes `Hello.class` and outputs "Hello from Java from within Go".

Just running `./run.sh` is also possible.

* `clojure.sh` is from the Clojure project.

Building the project and running `Hello.java` with `gojure`, using just:

    make

Works here.

However, running the modified `clojure.sh` script yields this result:

```
Got a define: /home/afr/.clojure/.cpcache/1491266507.libs
>> line:  -2 pc:   1 java/util/TimeZone.getSystemTimeZoneID(Ljava/lang/String;)Ljava/lang/String; 
>> line: 655 pc:  47 java/util/TimeZone.setDefaultZone()Ljava/util/TimeZone; 
>> line: 636 pc:  11 java/util/TimeZone.getDefaultRef()Ljava/util/TimeZone; 
>> line: 254 pc:  69 java/util/Date.<init>(IIIIII)V 
>> line:  71 pc:  65 java/util/zip/ZipUtils.dosToJavaTime(J)J 
>> line:  88 pc:   4 java/util/zip/ZipUtils.extendedDosToJavaTime(J)J 
>> line: 194 pc:  33 java/util/zip/ZipEntry.getTime()J 
>> line: 396 pc:  31 clojure/lang/RT.lastModified(Ljava/net/URL;Ljava/lang/String;)J 
>> line: 442 pc: 126 clojure/lang/RT.load(Ljava/lang/String;Z)V 
>> line: 425 pc:   5 clojure/lang/RT.load(Ljava/lang/String;)V 
>> line: 342 pc:2757 clojure/lang/RT.<clinit>()V 
>> line:  20 pc:  12 clojure/main.<clinit>()V 
>> line:  -1 pc:   0 ~shim.<bootstrap> 
>> line:  -1 pc:   0 ~shim.<return> 
panic: native method not found: java/util/TimeZone~getSystemTimeZoneID~(Ljava/lang/String;)Ljava/lang/String; [recovered]
	panic: native method not found: java/util/TimeZone~getSystemTimeZoneID~(Ljava/lang/String;)Ljava/lang/String;

goroutine 1 [running]:
github.com/zxh0/jvm.go/cpu._catchErr(0xc00006eea0)
	/home/afr/go/pkg/mod/github.com/zxh0/jvm.go@v0.0.0-20191204141628-129b147ebcc8/cpu/loop.go:119 +0x1a4
panic(0x5e7c20, 0xc002a32320)
	/usr/lib/go/src/runtime/panic.go:679 +0x1b2
github.com/zxh0/jvm.go/native.FindNativeMethod(0xc002a31080, 0x7f32ae)
	/home/afr/go/pkg/mod/github.com/zxh0/jvm.go@v0.0.0-20191204141628-129b147ebcc8/native/registry.go:35 +0x283
github.com/zxh0/jvm.go/instructions/reserved.(*InvokeNative).Execute(0x82a0e0, 0xc002a36200)
	/home/afr/go/pkg/mod/github.com/zxh0/jvm.go@v0.0.0-20191204141628-129b147ebcc8/instructions/reserved/invokenative.go:22 +0x52
github.com/zxh0/jvm.go/cpu._loop(0xc00006eea0)
	/home/afr/go/pkg/mod/github.com/zxh0/jvm.go@v0.0.0-20191204141628-129b147ebcc8/cpu/loop.go:78 +0xde
github.com/zxh0/jvm.go/cpu.Loop(0xc00006eea0)
	/home/afr/go/pkg/mod/github.com/zxh0/jvm.go@v0.0.0-20191204141628-129b147ebcc8/cpu/loop.go:54 +0x42
main.startJVM8(0xc0000a0210, 0xc000012090, 0x0, 0x0)
	/home/afr/clones/gojure/main.go:135 +0x74
main.main()
	/home/afr/clones/gojure/main.go:46 +0x67
```

Apparently, `java/util/TimeZone.getSystemTimeZoneID` is missing. This might be due to misconfiguration, or something else.

It could be because `-Dclojure.libfile` is ignored right now.

I'll just leave the project as "work in progress" at this point.

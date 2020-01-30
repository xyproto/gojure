.PHONY: clean distclean run

.DEFAULT_GOAL = run

ZULU := zulu8.44.0.11-ca-jdk8.0.242-linux_x64

$(ZULU):
	@curl -O 'https://cdn.azul.com/zulu/bin/$@.tar.gz' && \
	  tar zxf "$@.tar.gz" && \
	  rm "$@.tar.gz"

jre: | $(ZULU)
	@ln -sf $(ZULU)/jre

Hello.class:
	@javac Hello.java

gojure:
	@go build

run: jre Hello.class gojure
	@./gojure Hello

clean:
	rm -f gojure Hello.class

distclean: clean
	rm -rf $(ZULU) jre

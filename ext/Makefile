
webview_app: ext_package
	cd webview && go build -buildmode=c-shared -o webview

ext_package:
	go get github.com/zserge/webview
	touch ext_package

install: webview_app
	mv webview/webview ./webview_app

clean:
	rm -f webview_app
	rm -f ext_package

// webview commit 2019-1-23 16c93bcaeaeb6aa7bb5a1432de3bef0b9ecc44f3

package main

import "github.com/zserge/webview"
import "flag"
import "fmt"
import "os"
import "strings"
import "runtime"


/*
typedef char* (*callbkfn)(char**, char*, char*);
*/
import "C"

func EvalCallback(w webview.WebView, name string, value string, userdata string) {
  value = strings.Replace(value, "'", "\\'", -1)
  userdata = strings.Replace(userdata, "'", "\\'", -1)

  // for windows path
  if runtime.GOOS == "windows" {
    value = strings.Replace(value, "\\", "\\\\", -1)
    userdata = strings.Replace(userdata, "\\", "\\\\", -1)
  }

	w.Eval(fmt.Sprintf(`
    (function(){
      var cb = window.rpc_cb;
      if (!cb) {
        console.error("Not found RPC callback window.rpc_cb")
        return;
      }
      cb('%s', '%s', '%s')
    })()
  `, name, value, userdata))
}

func buildRpcHandler(rubycallback C.callbkfn) func(w webview.WebView, data string) {
  return func(w webview.WebView, data string) {
    fmt.Println("RPC CALL: ", data)

    s := strings.SplitN(data, ",", 2)
    action, userdata := s[0], ""
    if len(s) > 1 {
      userdata = s[1]
    }

  	switch {
  	case action == "close":
  		w.Terminate()
  	case action == "fullscreen":
  		w.SetFullscreen(true)
  	case action == "unfullscreen":
  		w.SetFullscreen(false)
    case action == "open":
      path := w.Dialog(
        webview.DialogTypeOpen, webview.DialogFlagFile & webview.DialogFlagDirectory,
        "Select a file or directory", "")
      EvalCallback(w, action, path, userdata)
    case action == "openfile":
      path := w.Dialog(
        webview.DialogTypeOpen, webview.DialogFlagFile,
        "Select a file", "")
      EvalCallback(w, action, path, userdata)
  	case action == "opendir":
      path := w.Dialog(
        webview.DialogTypeOpen, webview.DialogFlagDirectory,
        "Select a directory", "")
      EvalCallback(w, action, path, userdata)
    case action == "savefile":
      path := w.Dialog(webview.DialogTypeSave, 0, "Save file", "")
      EvalCallback(w, action, path, userdata)
    default:
      if rubycallback != nil {
        results := send_to_ruby(rubycallback, C.CString(action), C.CString(userdata))
        fmt.Println("Results are in: ", results)
        if results == "" {
          EvalCallback(w, "error", action, userdata)
        } else {
          EvalCallback(w, action, results, userdata)
        }
      } else {
        EvalCallback(w, "error", action, userdata)
      }
    }
  }
}

//export launch_from_c
func launch_from_c(fp C.callbkfn, url *C.char, title *C.char, width int, height int, resizable bool, debug bool) {
  fmt.Println("Setting callback addr to ", fp)
  rpchandler := buildRpcHandler(fp)
  // rpchandler := buildRpcHandler(nil)
  launch( C.GoString(url),
          C.GoString(title),
          width,
          height,
          resizable,
          debug,
          rpchandler,
        )
}

func launch(url string, title string, width int, height int, resizable bool, debug bool, rpchandler func(w webview.WebView, data string)) {
  w := webview.New(webview.Settings{
		URL: url,
		Title: title,
		Width: width,
		Height: height,
		Resizable: resizable,
    Debug: debug,
    ExternalInvokeCallback: rpchandler,
	})

  defer w.Exit()
  w.Run()
}


func main() {
  urlPtr := flag.String("url", "", "App URL")
  titlePtr := flag.String("title", "MyApp", "App title")
  widthPtr := flag.Int("width", 1100, "width of window")
  heightPtr := flag.Int("height", 800, "height of window")
  debugPtr := flag.Bool("debug", false, "debug mode")
  resizablePtr := flag.Bool("resizable", false, "Allow resize window")

  flag.Parse()

  if *urlPtr == "" {
    fmt.Fprintf(os.Stderr, "URL is required\n")
    os.Exit(1)
  }

  launch(
    *urlPtr,
    *titlePtr,
    *widthPtr,
    *heightPtr,
    *resizablePtr,
    *debugPtr,
    buildRpcHandler(nil),
  )
}

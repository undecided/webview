require 'timeout'
require 'open3'
require 'ffi'

module Webview
  class App
    extend FFI::Library
    attr_reader :app_out, :app_err, :app_process, :options

    ffi_lib File.expand_path('ext/webview_app', ROOT_PATH)
    attach_function :launch_from_c, [:string, :string, :string, :string, :bool, :bool], :void, blocking: true

    SIGNALS_MAPPING = if Gem.win_platform?
      {
        'QUIT' => 'EXIT',
      }
    else
      {} # don't map
    end

    def initialize(title: nil, width: nil, height: nil, resizable: nil, debug: false)
      @options = {
        title: title,
        width: width,
        height: height,
        resizable: !!resizable,
        debug: !!debug
      }
      # @options.delete_if { |k, v| v.nil? }
      @app_out = nil
      @app_err = nil
      @app_process = nil
    end

    def open(url)
      @thread = Thread.new do
        params = [url, *@options.values]
        sleep 1
        launch_from_c *params
      end
    end

    def close
      raise "not yet"
    end

    def join
      @thread.join
    end

    def kill
      @thread.kill
    end

    def signal(name)
      raise 'not yet'
    end
  end
end

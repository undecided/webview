require 'timeout'
require 'open3'
require 'ffi'

module Webview
  class App
    extend FFI::Library
    attr_reader :app_out, :app_err, :app_process, :options, :callbacks

    ffi_lib File.expand_path('ext/webview_app', ROOT_PATH)
    callback :incoming_rpc, [:string, :string], :string # callback_name, :calback_data_json --> :callback_return_json
    attach_function :launch_from_c, [:incoming_rpc, :string, :string, :string, :string, :bool, :bool], :void, blocking: true

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
      @callbacks = {}
      @callback_runner = build_callback_runner
    end

    def open(url)
      puts "OPENING (RUBYLAND)"
      @thread = Thread.new do
        params = [@callback_runner, url, *@options.values]
        sleep 1
        puts params.inspect
        launch_from_c *params
      end.join
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

    def build_callback_runner
      FFI::Function.new(:string, [:string, :string]) do |name, json_data|
        puts "RUBYRUNNER CALLED"
        puts "NAME: #{name}"
        puts "DATA: #{json_data}"
        run_callback(name.to_sym, JSON.parse(json_data))
        {test: :data}.to_json
      end
    end

    def register_callback(name, &block)
      @callbacks[name.to_sym] = block
    end

    def run_callback(name_sym, data)
      return "" unless @callbacks.key?(name)

      puts "RUBYLAND running callback #{name_sym} with data #{data}"
      {found: :ok, returned: @callbacks[name].call(data)}
    end

    def signal(name)
      raise 'not yet'
    end
  end
end

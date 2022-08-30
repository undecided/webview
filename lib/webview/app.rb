require 'timeout'
require 'open3'
require 'ffi'
require 'json'

module Webview
  class App
    extend FFI::Library
    attr_reader :app_out, :app_err, :app_process, :options, :callbacks

    ffi_lib File.expand_path('ext/webview_app', ROOT_PATH)
    callback :incoming_rpc, [:pointer, :string, :string], :void # callback_name, :calback_data_json --> :callback_return_json
    attach_function :launch_from_c, [:incoming_rpc, :string, :string, :string, :string, :bool, :bool], :void, blocking: false

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
        puts "Params passing from ruby: ", params.inspect
        launch_from_c *params
      end
    end

    def close
      @thread.kill
      raise "Trying to close with an exception. Isn't that nice."
    end

    def join
      @thread.join
    end

    def kill
      @thread.kill
    end

    def build_callback_runner
      FFI::Function.new(:void, [:pointer, :string, :string]) do |output, name, json_data|
        response = run_callback(name.to_sym, JSON.parse(json_data))
        write_string_to_pointer(response.to_json, output)
      end
    end

    def register_callback(name, &block)
      @callbacks[name.to_sym] = block
    end

    def run_callback(name_sym, data)
      return "" unless @callbacks.key?(name_sym)

      begin
        {found: :ok, response: @callbacks[name_sym].call(data)}
      rescue Exception => e
        {found: :error, response: {message: e.message, backtrace: e.backtrace} }
      end
    end

    def signal(name)
      raise "Attempted signal #{name} but signal not yet implemented"
    end

    def write_string_to_pointer(string, pointer)
      pointer.write_pointer(FFI::MemoryPointer.from_string(string).address)
    end
  end
end

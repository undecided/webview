module Webview
  class Error < StandardError; end

  ROOT_PATH = File.expand_path('../../', __FILE__)
end


require "webview/version"
require 'webview/app'

$LOAD_PATH << File.expand_path('../../../lib', __FILE__)

require 'webview'

app = Webview::App.new(title: 'Ruby Language', debug: true)
filepath = File.expand_path('../rpc.html', __FILE__)
app.open("file://#{filepath}")

app.register_callback :change_directory do |new_dir|
  directory = File.expand_path(File.join('.', new_dir))
  {directory_name: directory, files: files, folders: folders}.to_json
end

at_exit { app.close }
begin
  app.join
rescue Interrupt
  app.close
end

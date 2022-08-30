# $LOAD_PATH << File.expand_path('../../../lib', __FILE__)

require 'webview'

app = Webview::App.new(title: 'Ruby Language', resizable: true, debug: false)

app.register_callback :change_directory do |data|
  directory = File.expand_path(File.join(data['current_directory'], data['new_directory'])) + '/'
  files = Dir[File.join(directory, '*.*')].map { |f| f.sub(directory, '')}
  folders = Dir[File.join(directory, '*/')].map { |f| f.sub(directory, '')}
  {directory_name: directory, files: files, folders: folders}
end

filepath = File.expand_path('../rpc.html', __FILE__)
app.open("file://#{filepath}") # TODO: At the moment this blocks :(


at_exit { app.close }
begin
  app.join
rescue Interrupt
  app.close
end

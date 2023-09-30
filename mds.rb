#!/usr/bin/ruby

require 'redcarpet'
require 'socket'
require 'digest'
require 'rb-inotify'

port = 8000
file = "#{Dir.getwd}/#{ARGV[0]}"
server = TCPServer.new(port)

def watch_file(f)
  puts 'TRIGGER'
  notifier = INotify::Notifier.new
  notifier.watch(f, :modify) {sendreload}
  notifier.process
end

def sendpage()
rc = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
md = rc.render(File.read("#{Dir.getwd}/#{ARGV[0]}"))
html = "<!DOCTYPE html>
<html>
  <head>
    <link href='data:image/x-icon' rel='icon' />
  </head>
  <body>
    <!-- MARKDOWN BEGIN -->
    #{md}
    <!-- MARKDOWN END -->
    <script>
      const socket = new WebSocket('ws://localhost:8000');
      socket.addEventListener('message', e => {window.location.reload();});
    </script>
  </body>
</html>
"
    $session.print("HTTP/1.1 200\r\n")
    $session.print("Content-Type: text/html\r\n")
    $session.print("\r\n")
    $session.print(html)
end

def sendreload()
  response = "RELOAD"
  #STDERR.puts "Sending response: #{ response.inspect }"
  output = [0b10000001, response.size, response]
  $session.write output.pack("CCA#{ response.size }")
end

def handshake(websocket_key)
  #STDERR.puts "Websocket handshake detected with key: #{ websocket_key }"
  response_key = Digest::SHA1.base64digest([websocket_key, "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"].join)
  #STDERR.puts "Responding to handshake with key: #{ response_key }"
  wsresp = ""
  wsresp += "HTTP/1.1 101 Switching Protocols\r\n"
  wsresp += "Upgrade: websocket\r\n"
  wsresp += "Connection: Upgrade\r\n"
  wsresp += "Sec-WebSocket-Accept: #{response_key}\r\n"
  wsresp += "\r\n"
  $session.write wsresp
end

puts("#{Time.now}: Watching for modifications to #{file}")
puts("#{Time.now}: Starting server on port #{port}")
while $session = server.accept()

  http_request = ""
  while (line = $session.gets) && (line != "\r\n")
    http_request += line
  end
  #STDERR.puts http_request

  if (matches = http_request.match(/^Sec-WebSocket-Key: (\S+)/))
    handshake matches[1]
    Thread.new { watch_file file }
  else
    sendpage
  end
end

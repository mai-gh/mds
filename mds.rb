#!/usr/bin/ruby

require 'redcarpet'
require 'socket'
require 'digest'
require 'rb-inotify'

port = 8000
file = "#{Dir.getwd}/#{ARGV[0]}"
server = TCPServer.new(port)

def watch_file(f)
  puts "#{Time.now}: Reload"
  notifier = INotify::Notifier.new
  notifier.watch(f, :modify) {sendreload}
  notifier.process
end

def sendpage()
    # https://george-hawkins.github.io/basic-gfm-jekyll/redcarpet-extensions.html
  rc = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML,
    tables: true,
    fenced_code_blocks: true,
    strikethrough: true,
    with_toc_data: true,
  )
  md = rc.render(File.read("#{Dir.getwd}/#{ARGV[0]}"))
  gh_css = File.read("#{$0.split("/")[0...-1].join("/")}/github-markdown-dark_5.2.0_min.css")
  html = "<!DOCTYPE html>
<html>
  <head>
    <title>#{ARGV[0]}</title>
    <link href='data:image/x-icon' rel='icon' />
    <style>
      body { background-color: black; }
      .markdown-body {
        box-sizing: border-box;
        min-width: 200px;
        max-width: 980px;
        padding: 45px;
        margin: 0 auto !important;
      }
      @media (max-width: 767px) {
        .markdown-body { padding: 15px; }
      }
      #{gh_css}
    </style>
  </head>
  <body>
    <article class='markdown-body'>#{md}</article>
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

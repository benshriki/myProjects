import SimpleHTTPServer
import SocketServer
import time
from os import curdir, sep, system
from io import BytesIO
from myDataHandler import data_handler
#most server code frome :https://stackoverflow.com/questions/23264569/python-3-x-basehttpserver-or-http-server
import hashlib
hostName = "localhost"
hostPort = 9000
database = data_handler()


class MyServer(SimpleHTTPServer.SimpleHTTPRequestHandler):
	def do_POST(self):
		content_length = int(self.headers['Content-Length'])
		body = self.rfile.read(content_length)
		if "Search" in body:
			print(time.asctime(), "Handle Search")
			s_val = ((body.split('&'))[0]).split('=')[1]
			database.search(s_val)
		elif "Task1" in body:
			print(time.asctime(), "Handle Load Task1")
			database.loadtask1()
		elif "Selected" in body:
			print((time.asctime(), "Handle load Selected"))
			text=(body.split('&'))
			text.pop(0)
			selectedIds=[]
			for x in text:
				tmp=x.split('=')
				selectedIds.append(tmp[0])
			database.loadSelected(selectedIds)
		else:
			print(time.asctime(), "Handle clear")
			database.clear()

		self.do_GET()	

	def do_GET(self):	
		if self.path == "/":
			self.path = "/index.html"

		try:
			#Check the file extension required and
			#set the right mime type
			sendReply = False
			if "myTask" in self.path:
				database.clear()
			if self.path.endswith(".html"):
				mimetype = 'text/html'
				sendReply = True
			if self.path.endswith(".txt"):
				mimetype = 'text/html'
				sendReply = True
			if self.path.endswith(".jpg"):
				mimetype = 'image/jpg'
				sendReply = True
			if self.path.endswith(".gif"):
				mimetype = 'image/gif'
				sendReply = True
			if self.path.endswith(".js"):
				mimetype = 'application/javascript'
				sendReply = True
			if self.path.endswith(".css"):
				mimetype = 'text/css'
				sendReply = True

			if sendReply:
				#Open the static file requested and send it
				f = open(curdir + sep + self.path, 'rb') 
				self.send_response(200)
				self.send_header('Content-type', mimetype)
				self.end_headers()
				self.wfile.write(f.read())
				f.close()
			return

		except IOError:
			self.send_error(404, 'File Not Found: %s' % self.path)

			
myServer = SocketServer.TCPServer((hostName, hostPort), MyServer)
print(time.asctime(), "Server Starts - %s:%s" % (hostName, hostPort))

try:
	myServer.serve_forever()
except KeyboardInterrupt:
    pass

myServer.server_close()
print(time.asctime(), "Server Stops - %s:%s" % (hostName, hostPort))
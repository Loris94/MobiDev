import socketioserver


port = input("Please enter the server port (default 9099): ")
socketioserver.startServer(port)

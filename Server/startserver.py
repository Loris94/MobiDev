import socketioserver


port = input("Please enter the server port (default 9099): ")
mongoPort = input("Please enter the mongoDB server port (default 27017): ")
socketioserver.startServer(port, mongoPort)

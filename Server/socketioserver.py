import socketio
import eventlet
import classes_pb2
import datetime
import pymongo
import json, ast
from pymongo import MongoClient
from protobuf_to_dict import protobuf_to_dict
from bson import json_util



# Mongo init
mongoClient = MongoClient('localhost', 27017)
db = mongoClient['MDsensorsDB']

# Socket init
sio = socketio.Server(async_mode='eventlet', ping_timeout=10, ping_interval=2) # this will give us 10 seconds +- 2 precision in the disconnect. changing these value will be reflected to the client too.
app = socketio.WSGIApp(sio)

# Data Structure
session_map = dict()
last_received_data = dict() # ['sid' : timestamp, 'sid': timestamp] store the timestamp of the last sensor received by this sid

# Functions
@sio.event
def connect(sid, environ):
    headers = environ['headers_raw']
    session_map[sid] = dict()
    for key, value in headers:
        if (key == 'session'):
            session_map[sid]['session'] = value
        if (key == 'uuid'):
            session_map[sid]['uuid'] = value
    print 'Connected socket (' + sid + '): ', session_map[sid]


@sio.event
def disconnect(sid):
    if sid in last_received_data:
        del last_received_data[sid]
    print('disconnect ', sid)

def reconnect(sid):
    print('Reconnect: ', sid)

@sio.event
def getLastTimestamp(sid):
    # When a client connects it ask for the server latest timestamp stored to clear the buffer after a reconnect or a disconnect
    session = session_map[sid]['session'] # get the session from the map where we stored all the information about the user in the connect
    uuid = session_map[sid]['uuid'] # same
    timestamp = 0
    probes = db.probes
    # find in db the latest entry
    data = probes.find_one({"session": session, "uuid": uuid }, sort=[('probe.timestamp', pymongo.DESCENDING)])
    if (data != None):
        data = ast.literal_eval(json.dumps(data, default=json_util.default))
        timestamp = data['probe']['timestamp']
    return "LAST_TIMESTAMP", timestamp

@sio.event
def sensorUpdate(sid, buffer):
    #print("Sensor data received", buffer)
    print("Data array quantity received: ", len(buffer))
    for data in buffer:
        # Received a sensor data update
        #print("Sample:" , data)
        print("len sensor update: ", len(data))
        unwrapped = classes_pb2.SensorUpdate()
        unwrapped.ParseFromString(data)
        storeSensorUpdate(sid, unwrapped)
    print "Returning last timestamp: ", last_received_data[sid]
    return "LAST_TIMESTAMP", last_received_data[sid]

def storeSensorUpdate(sid, sensor_update):
    last_received_data[sid] = sensor_update.timestamp
    session = session_map[sid]['session']
    uuid = session_map[sid]['uuid']
    
    collection = db['probes']
    data = {
        "session": session,
        "uuid": uuid,
        "date": datetime.datetime.utcnow(),
        "probe" : protobuf_to_dict(sensor_update)
    }

    collection.insert_one(data)
#print("Storing sensor Update: ", data)


eventlet.wsgi.server(eventlet.listen(('0.0.0.0', 9099)), app)





# MobiDev

This project contains an iOS app that gathers sensors data from the phone and a python library that creates a server that logs 
the receiving data

## Prerequisites

* iOS version > 11.3 
* Python 2.7 on the server
* MongoDB on the server

All python dependencies are downloadable with pip:
* pip install python-socketio
* pip install eventlet
* pip install pymongo
* pip install protobuf-to-dict

## Client

Once the app starts, the first view that loads is a list of all the settable parameters. Click on the cell to edit (if editable) and on the switch to toggle the data gather.

### Server
Server address and port

### Session (optional)
Session name (see later for explanation) 

### Accelerometer/Gyroscope/Magnetometer/Compass 
Update interval: how frequently the sensor is going to send the data (in seconds). Smallest value is 0.1s

### Video Frames
* Compression: compression rate of the image that is taken from the camera, it ranges from 0 (lowest image quality, highest compression) to 1 (highest image quality, lowest compression). 
* FPS: how many frames are taken per seconds. Lowest: 1, Highest: 60
* Resolution: list of all possible frames resolution, incrementing the stepper will select a larger resolution 

### ARkit 6d poses/ Planes / Points cloud 
Don't have parameters, moreover planes and points cloud depend directly from the video frames ( activacting these will also activate video frames ) 

### Screenshots

The screenshots show all the client sensors and the parameters for accelerometer/video frames

<img src="./ReadMeImages/Image1.jpg" width="25%" height="25%"> <img src="./ReadMeImages/image5.jpg" width="25%" height="25%"> <img src="./ReadMeImages/image6.jpg" width="25%" height="25%">

And the interface once the app starts:  

<img src="./ReadMeImages/image2.png" width="25%" height="25%"> <img src="./ReadMeImages/image3.png" width="25%" height="25%"> <img src="./ReadMeImages/image4.png" width="25%" height="25%">

In these example all sensors are started, the camera feed also shows point clouds and planes. By swiping on the right it'll show a table with the connection status / buffers size / sensors's status. 

The connection status is also shown by a red/green dot in the upper right corner of the screen.

## Server

The library is inside the socketioserver.py file, to start the server just import the library and use the method startServer with the server port as parameter. An example is in the startserver.py file

## About the data

All the data is saved from the server in a MongoDB database. The name of the database is 'MDsensorsDB' and the collection is 'probes'. Every probe has this structure:
* ObjectID
* Date when the probe was received
* Session name, the one chosen from the app
* Uuid of the device that sent the probe
* Probe

Structure of the probe:
* timestamp: when it was gathered from the device
* data: data of the sensor. It can be of different kinds depending from the sensor that gathered the data. 

Important: Arkit poses/Points Cloud/Tracking state if chosen are embedded inside the JpegImage data type

All the sensors data gathered from the device is taken using Apple libraries and not edited, with the exception of video frames that are converted in jpeg.
CoreMotion is used for the accelerometer, gyroscope, magnetometer and CoreLocation for the compass.
Video Frames, arkit poses, planes and points clouds are taken with the arkit library

### Screenshots

The images below show an example of the data saved in the server database.


<img src="./ReadMeImages/image7.png" width="100%" height="25%">

Acceleration, magnetometer and gyro data are similar: they just have x, y and z coordinates. The compass also have magneticHeading and trueHeading.

<img src="./ReadMeImages/image8.png" width="100%" height="25%">

The video frame data contains the image itself, the arkitposes and points cloud. 
In the example at the transform poses data not every element of the matrix is shown. The third column has three elements while the fourth has four; this is because the "w" element in the third column is 0.

Important: arKitPoses can work without the video feed but the data will still be recorded inside a JpegImage probe ( the JpegImage string will be empty in that case ) 


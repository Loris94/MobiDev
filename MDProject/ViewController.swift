//
//  ViewController.swift
//  MDProject
//
//  Created by Loris D'Auria on 19/06/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion
import CoreLocation
import VideoToolbox

extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        if let cgImage = cgImage {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}


@available(iOS 11.3, *)
class ViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate,ARSessionDelegate, ARSCNViewDelegate {
    
    var videoFrame: Int = 0

    static var isClosing = false
    var flushStarted = false
    var backgroundClosingThread: DispatchWorkItem? = nil
    
    let operationQueue = OperationQueue()
    let motionManager = CMMotionManager()
    let locationManager = CLLocationManager()
    
    var profile: Profile = Profile()
    var UUID = UIDevice.current.identifierForVendor!.uuidString
    
    var socketController : SocketController? = nil
    
    var bufferDispatchQueue: DispatchQueue = DispatchQueue(label: "bufferOperationDispatchQueue")
    var buffer: Buffer? = nil
    var arSession: ARSession? = nil
    
    var slides: [UIView]? = nil
    
    @IBOutlet weak var uiScrollView: UIScrollView!
    
    
    // first page of the scroll view arkit camera, will appear only if the user wants ardata
    var arscnView: ARSCNView? = nil
    
    // second page of the scroll view, this will display sensorinfo and data usage. Will always appear
    @IBOutlet weak var sensorInfoUIScrollView: UIScrollView!
    
    @IBOutlet weak var realtimeInfoTable: UITableView!
    var updateCellsTimer = Timer()
    
    let realTimeTableStructure : [String:Any] = [
        "Status": [0,3],
        "Accelerometer":[1,3],
        "Gyroscope":[2:3],
        "Magnetometer":[3:4],
        "Compass":[4,5]
    ]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // SECTION 0 = STATUS INFO: CONNECTION TO SERVER, QUANTITY IN BUFFER, DATA SENT
        // SECTION 1 = ACCELEROMETER, 2 GYROSCOPE, 3 MAGNETOMETER, 4 COMPASS, 5 ARKIT 6D POSES, 6 PLANES, 7 POINT CLOUD
        switch section {
        case 0:
            return 3
        case 1:
            if self.profile.sensorList.getByName(name: "Accelerometer")!.status {
                return 3
            }
        case 2:
            if self.profile.sensorList.getByName(name: "Gyroscope")!.status {
                return 3
            }
        case 3:
            if self.profile.sensorList.getByName(name: "Magnetometer")!.status {
                return 3
            }
        case 4:
            if self.profile.sensorList.getByName(name: "Compass")!.status {
                return 5
            }
        case 5:
            if self.profile.sensorList.getByName(name: "ARkit 6d poses")!.status {
                return 3 //yaw pitch roll
            }
        default:
            return 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath[0] {
            case 0:
                if indexPath[1] == 0 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Connection to server"
                        if self.socketController?.isConnected() ?? false {
                            cell.InfoValue.text = "Connected"
                        } else {
                            cell.InfoValue.text = "Disconnected"
                        }
                        return cell
                    }
                }
                else if indexPath[1] == 1 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Sensor Buffer Size"
                        cell.InfoValue.text = String(buffer!.bufferSize["sensor"] ?? 0)
                        return cell
                    }
                }
                else if indexPath[1] == 2 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Image Buffer Size"
                        cell.InfoValue.text = String(buffer!.bufferSize["image"] ?? 0)
                        return cell
                    }
            }
            
            case 1:
                if indexPath[1] == 0 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Accelerometer x"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 1 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Accelerometer y"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 2 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Accelerometer z"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                }
            case 2:
                if indexPath[1] == 0 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Gyroscope x"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 1 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Gyroscope y"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 2 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Gyroscope z"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                }
            case 3:
                if indexPath[1] == 0 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Magnetometer x"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 1 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Magnetomerer y"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 2 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Magnetometer z"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                }
            case 4:
                if indexPath[1] == 0 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Compass x"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 1 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Compass y"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 2 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Compass z"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 3 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Compass heading"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 4 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Compass true heading"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                }
            case 5:
                if indexPath[1] == 0 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Raw"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 1 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Pitch"
                        cell.InfoValue.text = "-"
                        return cell
                    }
                } else if indexPath[1] == 2 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Roll"
                        cell.InfoValue.text = "-"
                        return cell
                    }
            }
            
            
            default:
                return UITableViewCell()
        
        
        }
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // NUMBER OF SENSOR + STATUS (+1)
        return self.profile.sensorList.sensorList.count + 1
    }
    
    func updateConnectionStatus(status: String) {
        DispatchQueue.main.async {
            
            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,0])) as? RealTimeInfoCell {
                cell.InfoValue.text = status
            }
            
        }
    }

    @objc func updateBufferSizeView() {
        //print("Update sensor view")
        DispatchQueue.main.async {
            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,0])) as? RealTimeInfoCell {
                if self.socketController?.isConnected() ?? false {
                    cell.InfoValue.text = "Connected"
                } else {
                    cell.InfoValue.text = "Disconnected"
                }
            }
            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,1])) as? RealTimeInfoCell {
                var value = Double(self.buffer!.bufferSize["sensor"] ?? 0)/1000
                if value < 0 {
                    self.buffer?.calculateSize(type: "sensor")
                    value = Double(self.buffer!.bufferSize["sensor"] ?? 0)/1000
                }
                cell.InfoValue.text = String(value) + "kB"
            }
            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,2])) as? RealTimeInfoCell {
                var value = Int((self.buffer!.bufferSize["image"] ?? 0)/1000)
                if value < 0 {
                    self.buffer?.calculateSize(type: "image")
                    value = Int(self.buffer!.bufferSize["image"] ?? 0)/1000
                }
                cell.InfoValue.text = String(value) + "kB"
            }
            
            
        }
    }
    
    func updateAccelerometerCell(accData: CMAccelerometerData) {
        DispatchQueue.main.async {
            let accProto = Utils.accelerometerToProto(elem: accData)
            for i in 0 ..< 3 {
                if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[1,i])) as? RealTimeInfoCell {
                    if i == 0 {
                        cell.InfoValue.text = String(accProto.x)
                    } else if i == 1 {
                        cell.InfoValue.text = String(accProto.y)
                    } else {
                        cell.InfoValue.text = String(accProto.z)
                    }
                    
                }
            }
        }
    }
    
    func updateGyroscopeCell(gyroData: CMGyroData) {
        DispatchQueue.main.async {
            let gyroProto = Utils.gyroToProto(elem: gyroData)
            for i in 0 ..< 3 {
                if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[2,i])) as? RealTimeInfoCell {
                    if i == 0 {
                        cell.InfoValue.text = String(gyroProto.x)
                    } else if i == 1 {
                        cell.InfoValue.text = String(gyroProto.y)
                    } else {
                        cell.InfoValue.text = String(gyroProto.z)
                    }
                    
                }
            }
        }
    }
    
    func updateMagnetometerCell(magnetometerData: CMMagneticField) {
        DispatchQueue.main.async {
            for i in 0 ..< 3 {
                if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[3,i])) as? RealTimeInfoCell {
                    if i == 0 {
                        cell.InfoValue.text = String(magnetometerData.x)
                    } else if i == 1 {
                        cell.InfoValue.text = String(magnetometerData.y)
                    } else if i == 2{
                        cell.InfoValue.text = String(magnetometerData.z)
                    }
                }
            }
        }
    }
    
    func updateCompassCell(compassData: CLHeading) {
        DispatchQueue.main.async {
            for i in 0 ..< 5 {
                if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[4,i])) as? RealTimeInfoCell {
                    switch i {
                    case 0:
                        cell.InfoValue.text = String(compassData.x)
                    case 1:
                        cell.InfoValue.text = String(compassData.y)
                    case 2:
                        cell.InfoValue.text = String(compassData.z)
                    case 3:
                        cell.InfoValue.text = String(compassData.magneticHeading.binade)
                    case 4:
                        cell.InfoValue.text = String(compassData.trueHeading.binade)
                    default:
                        print("")
                    }
                }
            }
        }
    }
    
    func updatePosesCell(posesData: simd_float3) {
        DispatchQueue.main.async {
            for i in 0 ..< 3 {
                if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[5,i])) as? RealTimeInfoCell {
                    switch i{
                        case 0:
                            cell.InfoValue.text = String(posesData.y)
                        case 1:
                            cell.InfoValue.text = String(posesData.x)
                        case 2:
                            cell.InfoValue.text = String(posesData.z)
                        default:
                            print("")
                    }
                }
            }
        }
    }
    
    @objc func sendSamples(NotificationData: Notification) {
        
        let payload_unwrapped: [Data] = NotificationData.userInfo!["payload"] as! [Data]
        let type = NotificationData.userInfo!["type"] as! String
        if self.socketController?.isConnected() ?? false {
            self.socketController?.sendSensorUpdateWithAck(samples: payload_unwrapped, callback: { error, timestamp in
                if !error {
                    self.buffer!.removeSamplesFromBuffer(type: type, timestamp: timestamp)
                    self.buffer!.shouldEmit[type] = true
                } else {
                    print("ErrorT")
                }
            })
        }
    }
    
    @objc func socketConnected(userInfo: Notification) {
        // The server will return the timestamp of the last received sample for this sessionName. If no samples are stored, it will return -1.
        // This is because after a connect but more precisely a REconnect, we can flush the buffer starting from this giver timestamp.
        // This timestamp could be very old, since a capture session with the same name could be already exist in the database and it may not be present in our buffer. just ignore then
        let last_ts_recv: Double = userInfo.userInfo!["timestamp"] as! Double
        self.buffer!.removeSamplesFromBuffer(type: "image", timestamp: last_ts_recv)
        self.buffer!.removeSamplesFromBuffer(type: "sensor", timestamp: last_ts_recv)

        print("Main - CONNECTED Server last ts: ", last_ts_recv)
        if !ViewController.isClosing {
            self.buffer!.setShouldEmit(value: true)
            self.updateConnectionStatus(status: "Connected")
        }
    }
    
    @objc func socketDisconnected() {
        self.buffer!.setShouldEmit(value: false)
        self.updateConnectionStatus(status: "Disconnected")
        print("Main - DISCONNECTED")
    }
    
    
    func flushImageBufferOneAtTime(imageBuffer: [Data], index: Int){
        if self.socketController == nil {
            return
        } else if self.socketController?.isConnected() ?? false {
            if index >= imageBuffer.count {
                return
            } else {
                print("ABC sent image: ", index)
                self.socketController?.sendSensorUpdateWithAck(samples: [imageBuffer[index]], callback: { error, timestamp in
                    
                    if !error {
                        print("ABC received ack for: ", index)
                        self.buffer!.removeSamplesFromBuffer(type: "image", timestamp: timestamp)
                        self.flushImageBufferOneAtTime(imageBuffer: imageBuffer, index: index+1)
                    } else {
                        DispatchQueue.global(qos: .background).async {
                            print("ABC error for: ", index)
                            sleep(1)
                            self.flushImageBufferOneAtTime(imageBuffer: imageBuffer, index: index)
                        }
                        
                    }
                })
            }
        } else {
            DispatchQueue.global(qos: .background).async {
                sleep(1)
                self.flushImageBufferOneAtTime(imageBuffer: imageBuffer, index: index)
            }
        }
    }
    
    func flushSensorBuffer(sensorBuffer: [Data]) {
        if self.socketController == nil {
            return
        } else if self.socketController?.isConnected() ?? false {
            self.socketController?.sendSensorUpdateWithAck(samples: sensorBuffer, callback: { error, timestamp in
                if !error {
                    self.buffer?.bufferSize["sensor"] = 0
                } else {
                    DispatchQueue.global(qos: .background).async {
                        sleep(1)
                        self.flushSensorBuffer(sensorBuffer: sensorBuffer)
                    }
                    
                }
            })
        }
    }
    
    
    func closingThread() {
        while self.socketController?.isConnected() == false {
            print("Socket is currently disconnected")
            sleep(1)
        }
        if self.socketController == nil {
            return 
        }
        let imageBuffer = self.buffer!.flushBuffer(type: "image")
        //self.bufferDispatchQueue.async {
        DispatchQueue.global().sync {
            self.flushImageBufferOneAtTime(imageBuffer: imageBuffer, index: 0)
        }
        //}

        
//        self.bufferDispatchQueue.async {
//            DispatchQueue.global().sync {
//                let sensorBuffer = self.buffer!.flushBuffer(type: "sensor")
//                if sensorBuffer.count > 0 {
//                    self.socketController?.sendSensorUpdateWithAck(samples: sensorBuffer, callback: { error, timestamp in
//                        //TODO: edge case, cosa fare quando sto flushando ma il socket non è connesso? la richiesta va in timeout, quindi bisognerebbe chiamare questa funzione ricorsivamente (o trovare una soluzione migliore)
//                        if (!error) {
//                            print("Done flushing sensor buffer, can close")
//                            self.buffer!.removeSamplesFromBuffer(type: "sensor", timestamp: timestamp)
//                        } else {
//                            print("Cannot finish sensor upload, not connected.")
//                        }
//                    })
//                }
//            }
//        }
        self.bufferDispatchQueue.async {
            DispatchQueue.global().sync {
                self.flushSensorBuffer(sensorBuffer: self.buffer!.flushBuffer(type: "sensor"))
            }
        }
        
        
        
    }
    
    // TODO: mettere alert con pulsanti per stoppare il thread o aspettare il finish dell'upload
    @objc func backAction(sender: UIBarButtonItem!) {
        self.stopAlert()
    }
    
    func dataStillPresentAlert() {
        let alert = UIAlertController(title: "Data not sent", message: "Some data is still present in the buffer and not sent. Continue sending or Stop?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { [weak alert] (action) -> Void in
            if self.buffer!.bufferSize["sensor"]!+self.buffer!.bufferSize["image"]! <= 0 {
                self.performSegue(withIdentifier: "goBackToSensors", sender: "A")
            }
        }))
        alert.addAction(UIAlertAction(title: "Stop", style: .default, handler: { [weak alert] (action) -> Void in
            self.performSegue(withIdentifier: "goBackToSensors", sender: "A")
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func stopAlert() {
        let alert = UIAlertController(title: "Are you sure you want to stop?", message: "Continuing will stop all sensors and start flushing remaining data", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { [weak alert] (action) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak alert] (action) -> Void in
            self.buffer!.setShouldEmit(value: false)
            ViewController.isClosing = true
            self.stopSensorGather()
            
            if self.buffer!.bufferSize["sensor"]!+self.buffer!.bufferSize["image"]! > 0 {
                if !self.flushStarted {
                    
                    self.bufferDispatchQueue.async {
                        DispatchQueue.global().sync {
                            self.closingThread()
                        }
                    }
                    
                    self.flushStarted = true
                    
                }
                self.dataStillPresentAlert()
            } else {
                self.performSegue(withIdentifier: "goBackToSensors", sender: "A")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.isClosing = false
        flushStarted = false
        self.buffer = Buffer(bufferLength: 1500, bufferDispatchQueue: self.bufferDispatchQueue)
        self.realtimeInfoTable.delegate = self
        self.realtimeInfoTable.dataSource = self
        if ARConfiguration.isSupported && self.profile.sensorList.getByName(name: "Video Frames")!.status {
            self.arscnView = ARSCNView()
            if self.profile.sensorList.getByName(name: "Planes")?.status ?? false {
                self.arscnView!.delegate = self
            }
            self.slides = [self.arscnView!, self.sensorInfoUIScrollView]
        } else {
            self.slides = [self.sensorInfoUIScrollView]
        }
        self.uiScrollView.delegate = self
        self.checkPermissions()
        self.hideKeyboardWhenTappedAround()
        self.navigationItem.setHidesBackButton(true, animated:true);
        let backItem = UIBarButtonItem(title: "Stop", style: UIBarButtonItem.Style.plain, target: self,action: #selector(self.backAction))
        self.navigationItem.leftBarButtonItem = backItem
        
        
        self.updateCellsTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateBufferSizeView), userInfo: nil, repeats: true)
        
        DispatchQueue.main.async {
            while true {
                sleep(1)
                if self.isViewLoaded {
//                    let w = self.view.safeAreaLayoutGuide.layoutFrame.width
//                    let h = self.view.safeAreaLayoutGuide.layoutFrame.height
//                    print("dadw: ", w, " ", h)
                    self.setUpScrollViews()
                    break
                }
                
            }
        }

        if ((socketController == nil)) {
            // We need to initialize socketcontroller here to pass the sessionName input by user
            socketController = SocketController(host: self.profile.serverAddress, port: self.profile.serverPort, session: self.profile.sessionName, uuid: self.UUID)
        }
        
        // Attach listeners to socket events
        NotificationCenter.default.addObserver(self, selector: #selector(socketConnected), name: .socket_connected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(socketDisconnected), name: .socket_disconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sendSamples), name: .sensor_buffer_enoughdata, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sendSamples), name: .image_buffer_enoughdata, object: nil)
    
        socketController?.connect()
        self.startSensorGather()

    }
    
    func setUpScrollViews() {
        self.setupSlideScrollView(slides: slides!)
        self.setupRealTimeTable()
        //self.setupCellsConstraints()
        self.updateViewConstraints()
    }

    func setupSlideScrollView(slides : [UIView]) {
        let w = self.view.safeAreaLayoutGuide.layoutFrame.width
        let h = self.view.safeAreaLayoutGuide.layoutFrame.height
        let x = self.view.safeAreaLayoutGuide.layoutFrame.minX
        let y = self.view.safeAreaLayoutGuide.layoutFrame.minY
        self.uiScrollView.frame = CGRect(x: x, y: y, width: w, height: h)
        self.uiScrollView.contentSize = CGSize(width: w * CGFloat(slides.count), height: h)
        self.uiScrollView.isPagingEnabled = true

        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: w * CGFloat(i), y: 0, width: w, height: h)
            self.uiScrollView.addSubview(slides[i])
        }
        
    }
    
    func setupRealTimeTable() {
        let w = self.view.safeAreaLayoutGuide.layoutFrame.width
        let h = self.view.safeAreaLayoutGuide.layoutFrame.height
        let x = self.view.safeAreaLayoutGuide.layoutFrame.minX
        let y = self.view.safeAreaLayoutGuide.layoutFrame.minY
        self.realtimeInfoTable.frame = CGRect(x: x, y: 0, width: w, height: h)
        //self.realtimeInfoTable.contentSize = CGSize(width: w, height: h)
    }
    
    func setupCellsConstraints() {
        for i in 0 ... self.profile.getNumberOfActiveSensors(){
            if let cell = self.realtimeInfoTable.cellForRow(at: [i,1]) as? RealTimeInfoCell {
                let horizontalConstraint = NSLayoutConstraint(item: cell.InfoValue, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
                cell.InfoValue.addConstraint(horizontalConstraint)
            }
        }
        
    }
    
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        print("Safe area insets changed: ")
        if UIDevice.current.orientation.isLandscape && self.isViewLoaded{
            print("Landscape")
            updateScrollView()
        } else if UIDevice.current.orientation.isPortrait && self.isViewLoaded{
            print("Portrait")
            updateScrollView()
        }
    }
    
    func updateScrollView() {
        let w: CGFloat
        if UIDevice.current.orientation.isLandscape {
            w = self.view.frame.width
        } else {
            w = self.view.safeAreaLayoutGuide.layoutFrame.width
        }
        let h = self.view.safeAreaLayoutGuide.layoutFrame.height
        let x: CGFloat
        if UIDevice.current.orientation.isLandscape {
            x = self.view.frame.minX
        } else {
            x = self.view.safeAreaLayoutGuide.layoutFrame.minX
        }
        let y = self.view.safeAreaLayoutGuide.layoutFrame.minY
        self.uiScrollView.frame = CGRect(x: x, y: y, width: w, height: h)
        self.uiScrollView.contentSize = CGSize(width: w * CGFloat(self.slides!.count), height: h)
        self.realtimeInfoTable.frame = CGRect(x: x, y: 0, width: w, height: h)
        for i in 0 ..< self.slides!.count {
            slides![i].removeFromSuperview()
            slides![i].frame = CGRect(x: w * CGFloat(i), y: 0, width: w, height: h)
            self.uiScrollView.addSubview(slides![i])
            //self.uiScrollView.insertSubview(slides![i], at: i)
        }
        print("Geom parameters: ", x, y, w, h)
    }
    
    func startSensorGather() {
        
//      ACCELEROMETER
        if motionManager.isAccelerometerAvailable && self.profile.sensorList.getByName(name: "Accelerometer")!.status {
            // min: 0.01
            motionManager.accelerometerUpdateInterval = self.profile.sensorList.getByName(name: "Accelerometer")?.parameters["Update Interval"] as! TimeInterval
            motionManager.startAccelerometerUpdates(to: self.operationQueue) { data, error  in
                self.bufferDispatchQueue.async {
                    DispatchQueue.global().sync {
                        self.buffer!.addProbe(type: "sensor", elem: data!)
                        self.updateAccelerometerCell(accData: data!)
                    }
                }
                
            }
        }
        
//      GYROSCOPE
        if motionManager.isGyroAvailable && self.profile.sensorList.getByName(name: "Gyroscope")!.status{
            motionManager.gyroUpdateInterval = self.profile.sensorList.getByName(name: "Gyroscope")?.parameters["Update Interval"] as! TimeInterval
            motionManager.startGyroUpdates(to: self.operationQueue) { data, error in
                self.bufferDispatchQueue.async {
                    DispatchQueue.global().sync {
                        self.buffer!.addProbe(type: "sensor", elem: data!)
                        self.updateGyroscopeCell(gyroData: data!)
                    }
                }
            }
        }
        
//      MAGNETOMETER
//      data!.gravity. IS THE SAME AS ACCELEROMETER
//      data!.rotationRate. GOING TO USE ARKIT 6D INSTEAD OF THIS
//      data!.attitude.pitch SAME
        if motionManager.isMagnetometerAvailable && self.profile.sensorList.getByName(name: "Magnetometer")!.status{
            motionManager.magnetometerUpdateInterval = self.profile.sensorList.getByName(name: "Magnetometer")?.parameters["Update Interval"] as! TimeInterval
            motionManager.startMagnetometerUpdates(to: self.operationQueue) { data, error in
                self.bufferDispatchQueue.async {
                    DispatchQueue.global().sync {
                        self.buffer!.addProbe(type: "sensor", elem: data!.magneticField)
                        self.updateMagnetometerCell(magnetometerData: data!.magneticField)
                    }
                }
            }
        }
        
//      COMPASS
        if CLLocationManager.locationServicesEnabled() && self.profile.sensorList.getByName(name: "Compass")!.status {
            
            locationManager.delegate = self
            locationManager.startUpdatingHeading()
        }
        
//      AR
        print("is AR supported: ", ARConfiguration.isSupported)
        if ARConfiguration.isSupported && self.profile.sensorList.getByName(name: "Video Frames")!.status {
            
            self.arSession = ARSession()
            self.arSession?.delegate = self
            self.arscnView?.session = self.arSession!
            if self.profile.sensorList.getByName(name: "Point cloud")!.status{
                self.arscnView?.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            }
            
            let arConfig = ARWorldTrackingConfiguration()
            arConfig.worldAlignment = ARConfiguration.WorldAlignment.gravity
            var resolutionsArray = ARWorldTrackingConfiguration.supportedVideoFormats
            resolutionsArray.reverse()
            arConfig.videoFormat = resolutionsArray[Int(self.profile.sensorList.getByName(name: "Video Frames")?.parameters["Resolution"] as! Double)]
            if self.profile.sensorList.getByName(name: "Planes")!.status{
                arConfig.planeDetection = .horizontal
            }
            
            let sessionConfig = arConfig
            arSession!.run(sessionConfig)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.lightGray

        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
        self.bufferDispatchQueue.async {
            DispatchQueue.global().sync {
                self.buffer?.addProbe(type: "sensor", elem: planeAnchor)
            }
        }
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.bufferDispatchQueue.async {
            DispatchQueue.global().sync {
                self.buffer?.addProbe(type: "sensor", elem: newHeading)
                self.updateCompassCell(compassData: newHeading)
            }
        }
    }
    
    
    
    func session(_: ARSession, didUpdate: ARFrame) {

        self.bufferDispatchQueue.async {
            
            DispatchQueue.global().sync {
                
                let fps = self.profile.sensorList.getByName(name: "Video Frames")?.parameters["FPS"] as? Double

                let frameEveryHowManySecs = Int(60 / Int(fps!))

                self.videoFrame += 1

                

                if self.videoFrame % frameEveryHowManySecs == 0 {
                    print("Resolution ", didUpdate.camera.imageResolution)
                    let compression = CGFloat(self.profile.sensorList.getByName(name: "Video Frames")?.parameters["Compression"] as! Double)
                    print("Compression ", compression)
                    let arKitPoses = self.profile.sensorList.getByName(name: "ARkit 6d poses")?.status
                    if arKitPoses ?? false {
                        self.updatePosesCell(posesData: didUpdate.camera.eulerAngles)
                    }
                    let planes = self.profile.sensorList.getByName(name: "Planes")?.status
                    let pointClouds = self.profile.sensorList.getByName(name: "Point cloud")?.status
                    self.buffer?.addProbe(type: "image", elem: (didUpdate, compression, arKitPoses, planes, pointClouds))
                    
                }

                if self.videoFrame == 60 {
                    self.videoFrame = 0
                }
            }
        }
        
    }
    
    func stopSensorGather() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
            print("Accelerometer stopped")
        }
        if motionManager.isGyroActive {
            motionManager.stopGyroUpdates()
            print("Gyro stopped")
        }
        if motionManager.isMagnetometerActive {
            motionManager.stopMagnetometerUpdates()
            print("Magnetometer stopped")
        }
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
            print("Device Motion stopped")
        }
        locationManager.stopUpdatingHeading()
        if self.arSession != nil {
            print("ARSession paused")
            self.arSession?.pause()
        }
    }
    

    func checkPermissions() {
        
        //check position permission for compass
        if self.profile.sensorList.getByName(name: "Compass")!.status {
            self.locationManager.requestWhenInUseAuthorization()
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goBackToSensors" {
            
            self.updateCellsTimer.invalidate()
            // Disconnect socket
            self.socketController?.disconnect()
            self.buffer = nil
            self.arSession = nil
            self.arscnView?.removeFromSuperview()
            self.arscnView = nil
            
            self.slides = nil
            self.backgroundClosingThread = nil
            
            
            // Remove listeners to socket events to prevent double firing
            NotificationCenter.default.removeObserver(self, name: .socket_connected, object: nil)
            NotificationCenter.default.removeObserver(self, name: .socket_disconnected, object: nil)
            NotificationCenter.default.removeObserver(self, name: .sensor_buffer_enoughdata, object: nil)
            NotificationCenter.default.removeObserver(self, name: .image_buffer_enoughdata, object: nil)
            
            // Destroy socketController because could be initialized with another sessionName
            self.socketController = nil

        }
            
       
        
    }
    
}


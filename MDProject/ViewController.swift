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


@available(iOS 11.0, *)
class ViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate,ARSessionDelegate {

    var isClosing = false
    let operationQueue = OperationQueue()
    let motionManager = CMMotionManager()
    let locationManager = CLLocationManager()
    
    var profile: Profile = Profile()
    
    //temp
    var acceletometerBuffer: [CMAccelerometerData] = []
    var gyroscopeBuffer: [CMGyroData] = []
    var magnetometerBuffer: [CMMagnetometerData] = []

    var UUID = UIDevice.current.identifierForVendor!.uuidString
    
    var socketController : SocketController? = nil
    
    var buffer: Buffer = Buffer(bufferLength: 1500)
    var arSession: ARSession? = nil
    
    let closeGroup = DispatchGroup()

    
    var canUseARKit: Bool {
        if #available(iOS 11.0, *) {
            return ARWorldTrackingConfiguration.isSupported
        } else {
            return false
        }
    }
    
    var slides: [UIView]? = nil
    
    @IBOutlet weak var uiScrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // first page of the scroll view arkit camera, will appear only if te user wants ardata
    var arscnView: ARSCNView!
    
    // second page of the scroll view, this will display sensorinfo and data usage. Will always appear
    @IBOutlet weak var sensorInfoUIScrollView: UIScrollView!
    
    
    @IBOutlet weak var realtimeInfoTable: UITableView!
    
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
                return 4
            }
        case 4:
            if self.profile.sensorList.getByName(name: "Compass")!.status {
                return 5
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
                        cell.InfoValue.text = "disconnected"
                        return cell
                    }
                }
                else if indexPath[1] == 1 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Sensor Buffer Size"
                        cell.InfoValue.text = String(buffer.bufferSize["sensor"] ?? 0)
                        return cell
                    }
                }
                else if indexPath[1] == 2 {
                    if let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as? RealTimeInfoCell{
                        cell.SensorInfo.text = "Sensor Image Size"
                        cell.InfoValue.text = String(buffer.bufferSize["image"] ?? 0)
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
            default:
                return UITableViewCell()
        
        
        }
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // NUMBER OF SENSOR + STATUS (+1)
        return self.profile.getNumberOfActiveSensors() + 1
    }
    
    func updateConnectionStatus(status: String) {
        DispatchQueue.main.async {
            
            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,0])) as? RealTimeInfoCell {
                cell.InfoValue.text = status
            }
            
        }
    }
    
//    let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
//        DispatchQueue.main.async {
//            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,1])) as? RealTimeInfoCell {
//                cell.InfoValue.text = String(self.buffer.bufferSize["sensor"] ?? 0)
//            }
//            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,2])) as? RealTimeInfoCell {
//                cell.InfoValue.text = String(self.buffer.bufferSize["image"] ?? 0)
//            }
//        }
//    })

    
    var timer = Timer()

    @objc func updateBufferSizeView() {
        DispatchQueue.main.async {
            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,1])) as? RealTimeInfoCell {
                cell.InfoValue.text = String(self.buffer.bufferSize["sensor"] ?? 0)
            }
            if let cell = self.realtimeInfoTable.cellForRow(at: IndexPath(indexes:[0,2])) as? RealTimeInfoCell {
                cell.InfoValue.text = String(self.buffer.bufferSize["image"] ?? 0)
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
    
    
    @objc func serverButtonAction(sender: UIButton!) {
        print("Button tapped")
    }
    
    @objc func sendSamples(NotificationData: Notification) {
        let payload_unwrapped: [Data] = NotificationData.userInfo!["payload"] as! [Data]
        let type = NotificationData.userInfo!["type"] as! String
        if self.socketController?.isConnected() ?? false {
            self.socketController?.sendSensorUpdateWithAck(samples: payload_unwrapped, callback: { error, timestamp in
                if !error {
                    self.buffer.removeSamplesFromBuffer(type: type, timestamp: timestamp)
                    self.buffer.shouldEmit[type] = true
                }
            })
        }
    }
    
//    @objc func sendImage() {
//        var samples : [Data] = []
//        let imageDataProto = SensorUpdate.with {
//            $0.type = "image"
//            $0.timestamp = 32443432432424.0432
//            $0.imageData = ImageProto.with {
//                $0.base64 = self.image
//            }
//        }
//        do {
//            let serialized = try imageDataProto.serializedData()
//            samples.append(serialized)
//            self.socketController?.sendSensorUpdateWithAck(samples: samples, callback: { err, timestamp in
//                if err {
//                    print("ERROR SANDING IMAGE")
//                } else {
//                    print("IMAGE SENT")
//                }
//            })
//        } catch {
//            print("CANNOT SERIALIZE IMAGE")
//        }
//    }
    
    @objc func socketConnected(userInfo: Notification) {
        // The server will return the timestamp of the last received sample for this sessionName. If no samples are stored, it will return -1.
        // This is because after a connect but more precisely a REconnect, we can flush the buffer starting from this giver timestamp.
        // This timestamp could be very old, since a capture session with the same name could be already exist in the database and it may not be present in our buffer. just ignore then
        let last_ts_recv: Double = userInfo.userInfo!["timestamp"] as! Double
        self.buffer.removeSamplesFromBuffer(type: "image", timestamp: last_ts_recv)
        self.buffer.removeSamplesFromBuffer(type: "sensor", timestamp: last_ts_recv)
        
        
        //Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(sendImage), userInfo: nil, repeats: true)

        print("Main - CONNECTED Server last ts: ", last_ts_recv)
        if !self.isClosing {
            self.buffer.setShouldEmit(value: true)
            self.updateConnectionStatus(status: "Connected")
        }
    }
    
    @objc func socketDisconnected() {
        // TODO: Update UI to inform user that is in disconnected state
        self.buffer.setShouldEmit(value: false)
        self.updateConnectionStatus(status: "Disconnected")
        print("Main - DISCONNECTED")
    }
    
    func flushSensors() {
        self.socketController?.sendSensorUpdateWithAck(samples: self.buffer.flushBuffer(type: "sensor"), callback: { error, timestamp in
            //TODO: edge case, cosa fare quando sto flushando ma il socket non è connesso? la richiesta va in timeout, quindi bisognerebbe chiamare questa funzione ricorsivamente (o trovare una soluzione migliore)
            if !error {
                print("Done flushing sensor buffer, can close")
                self.buffer.removeSamplesFromBuffer(type: "sensor", timestamp: timestamp)
            } else {
                print("Cannot finish upload, not connected.")
            }
        })
    }
    
    
    func closingThread() {
        while self.socketController?.isConnected() == false {
            print("Socket is currently disconnected")
            sleep(1)
        }
        
        let imageBuffer = self.buffer.flushBuffer(type: "image")
        if imageBuffer.count > 0 {
            closeGroup.enter()
            self.socketController?.sendSensorUpdateWithAck(samples: imageBuffer, callback: { error, timestamp in
                //TODO: edge case, cosa fare quando sto flushando ma il socket non è connesso? la richiesta va in timeout, quindi bisognerebbe chiamare questa funzione ricorsivamente (o trovare una soluzione migliore)
                if (!error) {
                    print("Done flushing image buffer, can close")
                    self.buffer.removeSamplesFromBuffer(type: "image", timestamp: timestamp)
                } else {
                    print("Cannot finish image upload, not connected.")
                }
                self.closeGroup.leave()
            })
        }

        let sensorBuffer = self.buffer.flushBuffer(type: "sensor")
        if sensorBuffer.count > 0 {
            closeGroup.enter()
            self.socketController?.sendSensorUpdateWithAck(samples: sensorBuffer, callback: { error, timestamp in
                //TODO: edge case, cosa fare quando sto flushando ma il socket non è connesso? la richiesta va in timeout, quindi bisognerebbe chiamare questa funzione ricorsivamente (o trovare una soluzione migliore)
                if (!error) {
                    print("Done flushing sensor buffer, can close")
                    self.buffer.removeSamplesFromBuffer(type: "image", timestamp: timestamp)
                } else {
                    print("Cannot finish sensor upload, not connected.")
                }
                self.closeGroup.leave()
            })
        }
        
        self.closeGroup.leave()
    }
    
    // TODO: mettere alert con pulsanti per stoppare il thread o aspettare il finish dell'upload
    @objc func backAction(sender: UIBarButtonItem!) {
        self.buffer.setShouldEmit(value: false)
        self.isClosing = true
        self.stopSensorGather()
        
        closeGroup.enter()
        let backgroundClosingThread = DispatchWorkItem {
            DispatchQueue.global(qos: .background).async {
                self.closingThread()
            }
        }
        DispatchQueue.global().async(execute: backgroundClosingThread)
        
        // TODO: se si vuole bloccare da UI il close background thread senza aspettare che abbia finito l'upload, cancellare il backgroundClosingThread e chiamare self.closeGroup.leave()

        closeGroup.notify(queue: .main) {
            print("All closing activities done.")
            self.performSegue(withIdentifier: "goBackToSensors", sender: "A")
        }
        if self.buffer.bufferSize["sensor"]!+self.buffer.bufferSize["image"]! > 0 {
            self.dataStillPresentAlert()
        }
        
        
    }
    
    func dataStillPresentAlert() {
        
        let alert = UIAlertController(title: "Data not sent", message: "Some data is still present in the buffer and not sent. Continue sending or Stop?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { [weak alert] (action) -> Void in
            if self.buffer.bufferSize["sensor"]!+self.buffer.bufferSize["image"]! > 0 {
                self.performSegue(withIdentifier: "goBackToSensors", sender: "A")
            }
        }))
        alert.addAction(UIAlertAction(title: "Stop", style: .default, handler: { [weak alert] (action) -> Void in
            self.closeGroup.leave()
            if self.buffer.bufferSize["sensor"]!+self.buffer.bufferSize["image"]! > 0 {
                self.performSegue(withIdentifier: "goBackToSensors", sender: "A")
            }
        }))
        self.present(alert, animated: true, completion: nil)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.realtimeInfoTable.delegate = self
        self.realtimeInfoTable.dataSource = self
        if ARConfiguration.isSupported && self.profile.sensorList.getByName(name: "Video Frames")!.status {
            self.arscnView = ARSCNView()
            self.slides = [self.arscnView, self.sensorInfoUIScrollView]
        } else {
            self.slides = [self.sensorInfoUIScrollView]
        }
        self.uiScrollView.delegate = self
        self.checkPermissions()
        self.hideKeyboardWhenTappedAround()
        self.navigationItem.setHidesBackButton(true, animated:true);
        let backItem = UIBarButtonItem(title: "Stop", style: UIBarButtonItem.Style.plain, target: self,action: #selector(self.backAction))
        self.navigationItem.leftBarButtonItem = backItem
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateBufferSizeView), userInfo: nil, repeats: true)
//        self.navigationItem.backBarButtonItem = backItem
        
        
        
        DispatchQueue.main.async {
            while true {
                sleep(1)
                if self.isViewLoaded {
                    let w = self.view.safeAreaLayoutGuide.layoutFrame.width
                    let h = self.view.safeAreaLayoutGuide.layoutFrame.height
                    print("dadw: ", w, " ", h)
                    self.setUpScrollViews()
                    break
                }
                
            }
        }
        
        
        
        if ((socketController == nil)) {
            // We need to initialize socketcontroller here to pass the sessionName input by user
            socketController = SocketController(host: self.profile.serverAddress, port: 9099, session: self.profile.sessionName, uuid: self.UUID)
        }
        
        // Attach listeners to socket events
        NotificationCenter.default.addObserver(self, selector: #selector(socketConnected), name: .socket_connected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(socketDisconnected), name: .socket_disconnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sendSamples), name: .sensor_buffer_enoughdata, object: nil)
    
        socketController?.connect()
        self.startSensorGather()

    }
    
    func setUpScrollViews() {
        
        self.setupSlideScrollView(slides: slides!)
        self.setupRealTimeTable()
        pageControl.numberOfPages = slides!.count
        pageControl.currentPage = 0
        view.bringSubviewToFront(self.pageControl)
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
        // TODO CAMBIARE LO 0 DALLA Y
        self.realtimeInfoTable.frame = CGRect(x: x, y: 0, width: w, height: h)
        //self.realtimeInfoTable.contentSize = CGSize(width: w, height: h)
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
        for i in 0 ..< self.slides!.count {
            slides![i].removeFromSuperview()
            slides![i].frame = CGRect(x: w * CGFloat(i), y: 0, width: w, height: h)
            self.uiScrollView.addSubview(slides![i])
            //self.uiScrollView.insertSubview(slides![i], at: i)
        }
        print("Geom parameters: ", x, y, w, h)
    }
    
    func startSensorGather() {
        // accelerometer
        // gyroscope
        // magnetometer
        // deviceMotion (has: )
    
        
//      ACCELEROMETER
        if motionManager.isAccelerometerAvailable && self.profile.sensorList.getByName(name: "Accelerometer")!.status {
            // min: 0.01
            motionManager.accelerometerUpdateInterval = self.profile.sensorList.getByName(name: "Accelerometer")?.parameters["Update Interval"] as! TimeInterval
            motionManager.startAccelerometerUpdates(to: self.operationQueue) { data, error  in
                self.buffer.addProbe(type: "sensor", elem: data!)
                self.updateAccelerometerCell(accData: data!)
            }
        }
        
//      GYROSCOPE
        if motionManager.isGyroAvailable && self.profile.sensorList.getByName(name: "Gyroscope")!.status{
            motionManager.gyroUpdateInterval = self.profile.sensorList.getByName(name: "Gyroscope")?.parameters["Update Interval"] as! TimeInterval
            motionManager.startGyroUpdates(to: self.operationQueue) { data, error in
                self.buffer.addProbe(type: "sensor", elem: data!)
                self.updateGyroscopeCell(gyroData: data!)
            }
        }
        
//      MAGNETOMETER
//      data!.gravity. IS THE SAME AS ACCELEROMETER
//      data!.rotationRate. GOING TO USE ARKIT 6D INSTEAD OF THIS
//      data!.attitude.pitch SAME
        if motionManager.isDeviceMotionAvailable && self.profile.sensorList.getByName(name: "Magnetometer")!.status{
            motionManager.deviceMotionUpdateInterval = self.profile.sensorList.getByName(name: "Magnetometer")?.parameters["Update Interval"] as! TimeInterval
            motionManager.startDeviceMotionUpdates(to: self.operationQueue) { data, error  in
                data!.magneticField.accuracy.rawValue
                data!.magneticField.field.x
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
            arSession = ARSession()
            self.arscnView.session = arSession!
            self.arscnView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            let sessionConfig = ARWorldTrackingConfiguration()
            arSession!.run(sessionConfig)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        newHeading
        locationManager.heading!.trueHeading
        locationManager.heading!.x
        locationManager.heading!.magneticHeading
    }

    
//    @available(iOS 11.0, *)
//    func startARKitGather(){
//
//        arSession = ARSession()
//
//        self.arscnView.session = arSession!
//        self.arscnView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
//        let sessionConfig = ARWorldTrackingConfiguration()
//
//        //sessionConfig.isAutoFocusEnabled = true
//
//        print("is ar supported: ",ARConfiguration.isSupported)
//
//        arSession!.run(sessionConfig)
//
//        var currentframe: ARFrame? = arSession!.currentFrame
//
//        //sleep(5)
//        currentframe?.rawFeaturePoints!.points[0].x // point clouds
//        if(currentframe != nil) {
//            print("Euler Angles: ",currentframe!.camera.transform)
//            print("Tracking State: ",currentframe!.camera.trackingState)
//            print(">> IMAGE BUFFER: ",currentframe!.capturedImage)
//            print("res: ", currentframe!.camera.imageResolution)
//            var a = UIImage(pixelBuffer: currentframe!.capturedImage)
//            // COMPRESSIONQUALITY VARIES FROM 0 TO 1
//
//            a?.jpegData(compressionQuality: 1)
//
//        }
//        else {
//            print("not ready yeet ")
//        }
//
//    }
    
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
        if self.arSession != nil {
            print("ARSession paused")
            self.arSession?.pause()
        }
    }
    

    // TODO SPOSTARE IN SENSORVIEWCONTROLLER
    func checkPermissions() {
        
        //check position permission for compass
        if self.profile.sensorList.getByName(name: "Compass")!.status {
            self.locationManager.requestWhenInUseAuthorization()
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goBackToSensors" {
            
            // Disconnect socket
            self.socketController?.disconnect()
            
            // Remove listeners to socket events to prevent double firing
            NotificationCenter.default.removeObserver(self, name: .socket_connected, object: nil)
            NotificationCenter.default.removeObserver(self, name: .socket_disconnected, object: nil)
            NotificationCenter.default.removeObserver(self, name: .sensor_buffer_enoughdata, object: nil)

            // Destroy socketController because could be initialized with another sessionName
            socketController = nil
            
            // TODO AS? STRING WILL HAVE TO BE CHANGED WITH AS? [CLASS FOR THE BUTTONS STRUCTURE]
            

            
            if let destinationVC = segue.destination as? SensorsViewController{
                //destinationVC.self.profile.sensorList = self.profile.sensorList
                
            }
            

            
            
        }
            
       
        
    }
    
}


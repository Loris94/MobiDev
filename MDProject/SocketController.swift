//
//  SocketManager.swift
//  MDProject
//
//  Created by Loris D'Auria on 06/07/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import SocketIO

extension Notification.Name {
    static let socket_connected = Notification.Name("socket_connected")
    static let socket_disconnected = Notification.Name("socket_disconnected")
    static let socket_reconnect = Notification.Name("socket_reconnect")
    static let socket_reconnect_attempt = Notification.Name("socket_reconnect_attempt")
    static let socket_last_sample_timestamp = Notification.Name("socket_last_sample_timestamp")
}

class SocketController {
    
    private var manager : SocketManager
    private var socket : SocketIOClient?
    var returned = false
    
    init(host: String, port: Int, session: String, uuid: String) {
        manager = SocketManager(socketURL: URL(string: "http://" + host + ":" + String(port))!, config: [.extraHeaders(["session": session, "uuid": uuid]), .log(true), .forceWebsockets(true), .forceNew(true), .reconnects(true), .reconnectWait(1)])
        socket = nil
    }
    
    func addConnectEventListener() {
        
        socket?.on(clientEvent: .connect) {data, ack in
            // data[0] corresponds to "LAST_TIMESTAMP" and data[1] to the actual timestamp, you can see it in the python server function "getLastTimestamp(sid)"
            self.socket?.emitWithAck("getLastTimestamp").timingOut(after: 20.0) { data in
                if data.count > 1 {
                    print("Socket Controller Connect Callback: ", data[1]);
                    // @objc func socketConnected(userInfo: Notification) in viewcontroller
                    NotificationCenter.default.post(name: .socket_connected, object: nil, userInfo: ["timestamp": data[1]])
                }
            }
            print("SocketController - Socket Connected!")
        }
        
        socket?.on(clientEvent: .disconnect) {data, ack in
            // Inform the buffer to stop sending new data to main class since we are in disconnected state
            // @objc func socketDisconnected() in viewcontroller

            NotificationCenter.default.post(name: .socket_disconnected, object: nil)
            print("SocketController - Socket Disconnected!")
        }
        
        socket?.on(clientEvent: .reconnect) {data, ack in
            // Inform the buffer to stop sending new data to main class since we are in disconnected state
            NotificationCenter.default.post(name: .socket_disconnected, object: nil)
            print("SocketController - Socket Reconnect attempt")
        }
        
    }
    
    func connect() {
        if (socket == nil) {
            print("SocketController - Socket does not exist, called connect");
            socket = manager.defaultSocket;
            addConnectEventListener()
            socket?.connect()
        } else if (socket?.status == SocketIOStatus.disconnected || socket?.status == SocketIOStatus.notConnected) {
            print("SocketController - Socket already present and disconnected, connecting");
            socket?.connect()
        }
    }
    
    func disconnect() {
        if (socket != nil) {
            print("SocketController - disconnect called")
            socket?.disconnect()
            manager.disconnect()
        }
    }
    
    func sendSensorUpdateNoAck(samples: [Data]) {
        try socket?.emit("sensorUpdate", samples)
    }
    
    func sendSensorUpdateWithAck(samples: [Data], callback: @escaping (Bool, Double) -> ()) {
        socket?.emitWithAck("sensorUpdate", samples).timingOut(after: 5.0) { data in
            if data.count > 1 {
                if let timestamp = data[1] as? Double {
                    print("Sensor update callback timestamp: ", timestamp);
                    callback(false, timestamp)
                }
            } else {
                print("Request TIMED OUT")
                callback(true, 0)
            }
        }
    }
    
    func isConnected() -> Bool {
        return self.socket?.status == SocketIOStatus.connected
    }
    
}

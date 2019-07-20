//
//  AppDelegate.swift
//  MDProject
//
//  Created by Loris D'Auria on 19/06/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var profile: Profile = Profile()
    
    var serverAddress: String = ""
    var serverPort: Int = 0
    var sessionName: String = ""
    var sensorList: SensorList = SensorList()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("Application started")
        loadDefaultProfile()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("Application going inactive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Application entering background")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("Application entering foreground")
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("Application becoming active")
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("Application terminating")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func loadDefaultProfile() {
        let file = "default.txt"
        let fileManager = FileManager.default
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            var defaultProfile: ProfileProto
            if !fileManager.fileExists(atPath: fileURL.absoluteString) {
                print("Default profile doesn't exist, creating new")
                defaultProfile = createDefaultProfile()
            } else {
                print("Default profile exists already, reading it")
                defaultProfile = readDefaultProfile() ?? createDefaultProfile()
            }
            self.sensorList = SensorList.fromProto(profileProto: defaultProfile)
            self.serverAddress = defaultProfile.serverAddress
            self.serverPort = Int(defaultProfile.serverPort)
            self.sessionName = defaultProfile.sessionName
            self.profile = Profile(serverAddress: self.serverAddress, serverPort: self.serverPort, sessionName: self.sessionName, sensorList: self.sensorList)

        }

    }
    
    func createDefaultProfile() -> ProfileProto {
        let defaultProfile = ProfileProto.with {
            $0.sessionName = "DefaultSession"
            $0.serverAddress = "192.168.1.58"
            $0.serverPort = 9099
            $0.sensor = [ SensorProto.with {
                $0.name = "Accelerometer"
                $0.status = true
                $0.parameter = [SensorParameterProto.with {
                    $0.key = "Update Interval"
                    $0.value = SensorParameterValueProto.with {
                        $0.doubleValue = 0.1
                    }
                    }]
                }, SensorProto.with {
                    $0.name = "Gyroscope"
                    $0.status = false
                    $0.parameter = [SensorParameterProto.with {
                        $0.key = "Update Interval"
                        $0.value = SensorParameterValueProto.with {
                            $0.doubleValue = 0.1
                        }
                        }]
                }, SensorProto.with {
                    $0.name = "Magnetometer"
                    $0.status = false
                    $0.parameter = [SensorParameterProto.with {
                        $0.key = "Update Interval"
                        $0.value = SensorParameterValueProto.with {
                            $0.doubleValue = 0.1
                        }
                        }]
                }, SensorProto.with {
                    $0.name = "Compass"
                    $0.status = false
                    $0.parameter = [SensorParameterProto.with {
                        $0.key = "Update Interval"
                        $0.value = SensorParameterValueProto.with {
                            $0.doubleValue = 40
                        }
                        }]
                }, SensorProto.with {
                    $0.name = "Video Frames"
                    $0.status = false
                    $0.parameter = [SensorParameterProto.with {
                        $0.key = "Resolution"
                        $0.value = SensorParameterValueProto.with {
                            $0.doubleValue = 0
                        }
                        }, SensorParameterProto.with {
                            $0.key = "Compression"
                            $0.value = SensorParameterValueProto.with {
                                $0.doubleValue = 1
                            }
                        }, SensorParameterProto.with {
                            $0.key = "FPS"
                            $0.value = SensorParameterValueProto.with {
                                $0.doubleValue = 30
                            }
                        }]
                }, SensorProto.with {
                    $0.name = "ARkit 6d poses"
                    $0.status = false
                }, SensorProto.with {
                    $0.name = "Planes"
                    $0.status = false
                }, SensorProto.with {
                    $0.name = "Point cloud"
                    $0.status = false
            }]
        }
        
        
        let file = "default.txt"
        let fileManager = FileManager.default
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            var serializedDefaultProfile: Data
            do {
                try serializedDefaultProfile = defaultProfile.serializedData()
                try serializedDefaultProfile.write(to: fileURL)
                print("Encoded default profile")
            } catch {
                print("Encoding Error")
            }
        }
        return defaultProfile
    }

    func readDefaultProfile() -> ProfileProto? {
        let file = "default.txt"
        let fileManager = FileManager.default
        if let dir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            do {
                let defaultProfileData = try ProfileProto(serializedData: Data(contentsOf: fileURL))
                return defaultProfileData
            }
            catch {
                print("Error reading default profile")
            }
        }
        return nil
    }
    


}


import UIKit
import Flutter
import CoreBluetooth

@main
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "com.example.bluetooth.ios"
    private var centralManager: CBCentralManager?
    private var targetPeripheral: CBPeripheral?
    private var resultCallback: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "connectToDevice":
                self.resultCallback = result
                self.initializeBluetooth()
            case "checkBluetoothConnection":
                self.checkBluetoothConnection(result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func initializeBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    private func connectToDevice() {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            resultCallback?(
                FlutterError(code: "BLUETOOTH_DISABLED", 
                             message: "Bluetooth is disabled on this device", 
                             details: nil)
            )
            return
        }

        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        centralManager.scanForPeripherals(withServices: nil, options: options)
    }

    private func checkBluetoothConnection(_ result: @escaping FlutterResult) {
        guard let centralManager = centralManager else {
            result(false)
            return
        }

        result(centralManager.state == .poweredOn)
    }
}

extension AppDelegate: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectToDevice()
        case .poweredOff, .unauthorized, .unsupported, .unknown, .resetting:
            resultCallback?(
                FlutterError(code: "BLUETOOTH_UNAVAILABLE", 
                             message: "Bluetooth is not available", 
                             details: nil)
            )
        @unknown default:
            resultCallback?(
                FlutterError(code: "UNKNOWN_ERROR", 
                             message: "An unknown error occurred", 
                             details: nil)
            )
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "Gelius GP-TWS033" {
            targetPeripheral = peripheral
            central.stopScan()
            central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        resultCallback?("A2DP connected successfully")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        resultCallback?(
            FlutterError(code: "CONNECTION_FAILED", 
                         message: "Failed to connect to the Bluetooth device", 
                         details: error?.localizedDescription)
        )
    }
}

package com.example.health_controller_app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.bluetooth"
    private val TARGET_DEVICE_NAME = "MBT-APG"
    private val REQUEST_ENABLE_BT = 1
    private val BLUETOOTH_PERMISSION_REQUEST = 2
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var targetDevice: BluetoothDevice? = null
    private lateinit var resultCallback: MethodChannel.Result
    private var bluetoothSocket: BluetoothSocket? = null
    private val UUID_SPP = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "connectToDevice" -> {
                    resultCallback = result
                    requestPermissionsAndEnableBluetooth()
                }
                "checkBluetoothConnection" -> {
                    checkBluetoothConnection(result)
                }
                "disconnectFromDevice" -> {
                    disconnectFromDevice(result)
                }
                "sendData" -> {
                    val byteData = call.arguments as ByteArray
                    sendDataToDevice(byteData, result)
                }
                "receiveData" -> {
                    receiveDataFromDevice(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPermissionsAndEnableBluetooth() {
        val permissions = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
        } else {
            permissions.add(Manifest.permission.BLUETOOTH)
            permissions.add(Manifest.permission.BLUETOOTH_ADMIN)
        }
        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)

        if (permissions.all { ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED }) {
            enableBluetooth()
        } else {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), BLUETOOTH_PERMISSION_REQUEST)
        }
    }

    private fun enableBluetooth() {
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            resultCallback.error("BLUETOOTH_UNSUPPORTED", "Bluetooth is not supported on this device", null)
            return
        }

        if (!bluetoothAdapter!!.isEnabled) {
            val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT)
        } else {
            connectToDevice()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_ENABLE_BT) {
            if (resultCode == RESULT_OK) {
                connectToDevice()
            } else {
                Toast.makeText(this, "Bluetooth activation canceled", Toast.LENGTH_SHORT).show()
                resultCallback.error("BLUETOOTH_NOT_ENABLED", "Bluetooth activation canceled", null)
            }
        }
    }

    private fun connectToDevice() {
        val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices
        if (pairedDevices != null && pairedDevices.isNotEmpty()) {
            for (device in pairedDevices) {
                if (device.name == TARGET_DEVICE_NAME) {
                    bluetoothAdapter?.cancelDiscovery()
                    targetDevice = device
                    createBondAndConnect(device)
                    return
                }
            }
            resultCallback.error("DEVICE_NOT_FOUND", "Target device not found among paired devices", null)
        } else {
            resultCallback.error("NO_DEVICES_FOUND", "No paired devices found", null)
        }
    }

    private fun createBondAndConnect(device: BluetoothDevice) {
        if (device.bondState != BluetoothDevice.BOND_BONDED) {
            device.createBond()
            Handler(Looper.getMainLooper()).postDelayed({
                if (device.bondState == BluetoothDevice.BOND_BONDED) {
                    connectToDeviceSocket(device)
                } else {
                    resultCallback.error("BONDING_FAILED", "Failed to bond with the device", null)
                }
            }, 5000)
        } else {
            connectToDeviceSocket(device)
        }
    }

    private fun connectToDeviceSocket(device: BluetoothDevice) {
        try {
            bluetoothSocket = device.createRfcommSocketToServiceRecord(UUID_SPP)
            bluetoothSocket?.connect()

            if (bluetoothSocket?.isConnected == true) {
                resultCallback.success("Connected to ${device.name}")
            } else {
                resultCallback.error("CONNECTION_FAILED", "Could not connect to the device", null)
            }
        } catch (e: IOException) {
            resultCallback.error("CONNECTION_ERROR", "Failed to connect to the device", e.message)
        }
    }

    private fun checkBluetoothConnection(result: MethodChannel.Result) {
        result.success(bluetoothSocket?.isConnected == true)
    }

    private fun disconnectFromDevice(result: MethodChannel.Result) {
        try {
            bluetoothSocket?.close()
            bluetoothSocket = null
            result.success("Disconnected from device")
        } catch (e: IOException) {
            result.error("DISCONNECTION_ERROR", "Failed to disconnect from the device", e.message)
        }
    }

    private fun sendDataToDevice(data: ByteArray, result: MethodChannel.Result) {
        if (bluetoothSocket?.isConnected == true) {
            try {
                bluetoothSocket!!.outputStream.write(data)
                bluetoothSocket!!.outputStream.flush()
                result.success("Data sent successfully")
            } catch (e: IOException) {
                result.error("SEND_ERROR", "Failed to send data", e.message)
            }
        } else {
            result.error("NOT_CONNECTED", "Bluetooth is not connected", null)
        }
    }

    private fun receiveDataFromDevice(result: MethodChannel.Result) {
        if (bluetoothSocket?.isConnected == true) {
            try {
                val inputStream = bluetoothSocket!!.inputStream
                val buffer = ByteArray(1024)
                val bytesRead = inputStream.read(buffer)

                if (bytesRead > 0) {
                    val receivedData = buffer.copyOf(bytesRead)
                    result.success(receivedData)
                } else {
                    result.error("NO_DATA", "No data received", null)
                }
            } catch (e: IOException) {
                result.error("RECEIVE_ERROR", "Failed to receive data", e.message)
            }
        } else {
            result.error("NOT_CONNECTED", "Bluetooth is not connected", null)
        }
    }
}

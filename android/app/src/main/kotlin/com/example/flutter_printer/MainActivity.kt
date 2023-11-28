package com.example.flutter_printer

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import android.util.Log

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var bluetoothSocket: BluetoothSocket? = null
    private var inputStream: InputStream? = null
    private var outputStream: OutputStream? = null
    private val connectedDevices = mutableMapOf<String, Boolean>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com/example/flutter_printer/bluetooth")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBluetoothDevices" -> getBluetoothDevices(result)
                "connectToDeviceByAddress" -> {
                    val address = call.argument<String>("address")
                    val data = call.argument<ArrayList<Byte>>("data")?.toByteArray()
                    connectToDeviceByAddress(address, data, result)
                }                
                
                
                "disconnect" -> disconnect(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun getBluetoothDevices(result: MethodChannel.Result) {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_NOT_AVAILABLE", "Bluetooth não disponível", null)
            return
        }

        val pairedDevices: Set<BluetoothDevice> = bluetoothAdapter.bondedDevices
        val devicesList = pairedDevices.map { device ->
            mapOf(
                "name" to device.name,
                "address" to device.address,
                "isConnected" to isConnected(device)
            )
        }
        result.success(devicesList)
    }

    private fun connectToDeviceByAddress(address: String?, data: ByteArray?, result: MethodChannel.Result) {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_NOT_AVAILABLE", "Bluetooth não disponível", null)
            return
        }
    
        val device = address?.let { bluetoothAdapter.getRemoteDevice(it) }
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Dispositivo não encontrado", null)
            return
        }
    
        val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        try {
            bluetoothSocket = device.createRfcommSocketToServiceRecord(uuid)
            CoroutineScope(Dispatchers.IO).launch {
                connectAndManageSocket(bluetoothSocket, data, result)
            }
        } catch (e: IOException) {
            result.error("SOCKET_CREATION_FAILED", "Falha na criação do socket", null)
        }
    }

    private fun connectAndManageSocket(socket: BluetoothSocket?, data: ByteArray?, result: MethodChannel.Result) {
        try {
            socket?.connect()
            inputStream = socket?.inputStream
            outputStream = socket?.outputStream
    
            if (data != null) {
                writeData(data, result)
            } else {
                result.error("NO_DATA_PROVIDED", "No data provided to write", null)
            }
        } catch (e: IOException) {
            CoroutineScope(Dispatchers.Main).launch {
                result.error("CONNECTION_FAILED", "Failed to connect to device", null)
            }
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        try {
            closeConnection()
            result.success(null)
        } catch (e: IOException) {
            result.error("DISCONNECTION_FAILED", "Falha ao desconectar", null)
        }
    }

    private fun writeData(data: ByteArray, result: MethodChannel.Result) {
        try {
            val chunkSize = 505 // Tamanho do chunk, pode ajustar conforme necessário
            for (i in data.indices step chunkSize) {
                val end = minOf(i + chunkSize, data.size)
                outputStream?.write(data.copyOfRange(i, end))
            }
            closeConnection() // Fechar a conexão após a escrita dos dados
            result.success(null)
        } catch (e: IOException) {
            result.error("WRITE_FAILED", "Failed to write data", null)
        } catch (e: InterruptedException) {
            result.error("INTERRUPTED", "Thread interrupted during write", null)
        }
    }

    private fun closeConnection() {
        try {
            inputStream?.close()
            outputStream?.close()
            bluetoothSocket?.close()
            bluetoothSocket = null
        } catch (e: IOException) {
            // Handle the exception
        }
    }

    private fun isConnected(device: BluetoothDevice): Boolean {
        return connectedDevices[device.address] == true
    }
}

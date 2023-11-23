package com.example.flutter_printer

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.util.Log
import androidx.annotation.NonNull
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

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var mmSocket: BluetoothSocket? = null
    private var mmInStream: InputStream? = null
    private var mmOutStream: OutputStream? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com/example/flutter_printer/bluetooth")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getBluetoothDevices" -> getBluetoothDevices(result)
                "connectToDeviceByAddress" -> {
                    val address = call.argument<String>("address")
                    val data = call.argument<ArrayList<Byte>>("data")?.toByteArray()
                    connectToDeviceByAddress(address, data)
                }
                "disconnect" -> disconnect(result)
                "writeData" -> {
                    val data = call.argument<ByteArray>("data")
                    writeData(data)
                }
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
            val isConnected = checkBluetoothDeviceConnection(device)
            mapOf(
                "name" to device.name,
                "address" to device.address,
                "isConnected" to isConnected
            )
        }
        result.success(devicesList)
    }

    private fun checkBluetoothDeviceConnection(device: BluetoothDevice): Boolean {
        // Exemplo: Verificar se há um socket conectado para o dispositivo Bluetooth
    
        // Obter um socket seguro (BluetoothSocket) para o dispositivo
        val socket: BluetoothSocket? = device.createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"))
    
        // Verificar se o socket está conectado
        return socket?.isConnected == true
    }

    private fun connectToDeviceByAddress(address: String?, data: ByteArray?) {
        println(address)
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            // result.error("BLUETOOTH_NOT_AVAILABLE", "Bluetooth não disponível", null)
            println("if 1")
            return
        }

        val device = address?.let { bluetoothAdapter.getRemoteDevice(it) }
        if (device == null) {
            println("if 2")
            // result.error("DEVICE_NOT_FOUND", "Dispositivo não encontrado", null)
            return
        }

        val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        try {
            mmSocket = device.createRfcommSocketToServiceRecord(uuid)
            CoroutineScope(Dispatchers.IO).launch {
                connectAndManageSocket(mmSocket, data)
            }
        } catch (e: IOException) {
            // result.error("SOCKET_CREATION_FAILED", "Falha na criação do socket", null)
        }
    }

    private fun connectAndManageSocket(socket: BluetoothSocket?, data: ByteArray?) {
        try {
            println(data)
            socket?.connect()
            mmInStream = socket?.inputStream
            mmOutStream = socket?.outputStream

            mmOutStream?.write(data)
            CoroutineScope(Dispatchers.Main).launch {
                // result.success(null) // Conexão bem-sucedida
                println("sucesso")
            }
        } catch (e: IOException) {
            CoroutineScope(Dispatchers.Main).launch {
                // result.error("CONNECTION_FAILED", "Failed to connect to device", null)
            }
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        try {
            mmInStream?.close()
            mmOutStream?.close()
            mmSocket?.close()
            result.success(null) // Desconexão bem-sucedida
        } catch (e: IOException) {
            result.error("DISCONNECTION_FAILED", "Falha ao desconectar", null)
        }
    }

    private fun writeData(data: ByteArray?) {
        try {
            if (data != null) {
                mmOutStream?.write(data)
            }
        } catch (e: IOException) {
        }
    }
}

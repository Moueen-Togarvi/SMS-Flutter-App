package com.bluechat.bluechat

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private lateinit var bridge: BlueChatBluetoothBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = BlueChatBluetoothBridge(this, flutterEngine)
    }

    override fun onDestroy() {
        if (::bridge.isInitialized) {
            bridge.dispose()
        }
        super.onDestroy()
    }
}

private class BlueChatBluetoothBridge(
    private val activity: FlutterActivity,
    flutterEngine: FlutterEngine,
) {
    private val serviceUuid: UUID = UUID.fromString("3e246bd2-4f2f-48f2-82b1-7f3568f3f003")
    private val serviceName = "BlueChatOfflineMessaging"
    private val ioExecutor: ExecutorService = Executors.newCachedThreadPool()
    private val accepting = AtomicBoolean(false)

    private var connectionSink: EventChannel.EventSink? = null
    private var deviceSink: EventChannel.EventSink? = null
    private var messageSink: EventChannel.EventSink? = null
    private var errorSink: EventChannel.EventSink? = null
    private var socket: BluetoothSocket? = null
    private var serverSocket: BluetoothServerSocket? = null
    private var reader: BufferedReader? = null
    private var writer: BufferedWriter? = null
    private var discoveryReceiver: BroadcastReceiver? = null

    private val adapter: BluetoothAdapter? by lazy {
        val manager = activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        manager.adapter
    }

    init {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bluechat/bluetooth_methods")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        startServer()
                        result.success(isBluetoothEnabled())
                    }
                    "isEnabled" -> result.success(isBluetoothEnabled())
                    "startDiscovery" -> runCatching { startDiscovery() }.fold(
                        onSuccess = { result.success(null) },
                        onFailure = { result.error("DISCOVERY_FAILED", it.message, null) },
                    )
                    "stopDiscovery" -> runCatching { stopDiscovery() }.fold(
                        onSuccess = { result.success(null) },
                        onFailure = { result.error("DISCOVERY_STOP_FAILED", it.message, null) },
                    )
                    "pairedDevices" -> runCatching { pairedDevices() }.fold(
                        onSuccess = { result.success(it) },
                        onFailure = { result.error("PAIRED_DEVICES_FAILED", it.message, null) },
                    )
                    "connect" -> {
                        val address = call.argument<String>("address")
                        if (address.isNullOrBlank()) {
                            result.error("INVALID_ADDRESS", "Missing Bluetooth address.", null)
                        } else {
                            connect(address)
                            result.success(null)
                        }
                    }
                    "disconnect" -> {
                        disconnect()
                        result.success(null)
                    }
                    "sendRaw" -> {
                        val packet = call.argument<String>("packet")
                        if (packet.isNullOrBlank()) {
                            result.error("INVALID_PACKET", "Missing packet.", null)
                        } else {
                            sendRaw(packet)
                            result.success(null)
                        }
                    }
                    "makeDiscoverable" -> {
                        makeDiscoverable()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        eventChannel(flutterEngine, "bluechat/bluetooth_connection") { connectionSink = it }
        eventChannel(flutterEngine, "bluechat/bluetooth_devices") { deviceSink = it }
        eventChannel(flutterEngine, "bluechat/bluetooth_messages") { messageSink = it }
        eventChannel(flutterEngine, "bluechat/bluetooth_errors") { errorSink = it }
    }

    private fun eventChannel(
        flutterEngine: FlutterEngine,
        name: String,
        assign: (EventChannel.EventSink?) -> Unit,
    ) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, name).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) = assign(events)
                override fun onCancel(arguments: Any?) = assign(null)
            },
        )
    }

    @SuppressLint("MissingPermission")
    private fun startServer() {
        if (!hasConnectPermission() || accepting.getAndSet(true)) return
        ioExecutor.execute {
            while (accepting.get()) {
                try {
                    serverSocket = adapter?.listenUsingRfcommWithServiceRecord(serviceName, serviceUuid)
                    val accepted = serverSocket?.accept()
                    if (accepted != null) {
                        attachSocket(accepted)
                    }
                } catch (error: IOException) {
                    if (accepting.get()) emitError("SERVER_ERROR", error.message ?: "Bluetooth server failed.")
                } finally {
                    runCatching { serverSocket?.close() }
                    serverSocket = null
                }
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun connect(address: String) {
        if (!hasConnectPermission()) {
            emitError("PERMISSION_DENIED", "Bluetooth connect permission is required.")
            return
        }
        emitConnection("connecting")
        ioExecutor.execute {
            try {
                adapter?.cancelDiscovery()
                val device = adapter?.getRemoteDevice(address)
                    ?: throw IOException("Device not found.")
                val nextSocket = device.createRfcommSocketToServiceRecord(serviceUuid)
                nextSocket.connect()
                attachSocket(nextSocket)
            } catch (error: Exception) {
                emitConnection("disconnected")
                emitError("CONNECT_FAILED", error.message ?: "Connection failed.")
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun attachSocket(nextSocket: BluetoothSocket) {
        disconnect(closeServer = false)
        socket = nextSocket
        reader = BufferedReader(InputStreamReader(nextSocket.inputStream, Charsets.UTF_8))
        writer = BufferedWriter(OutputStreamWriter(nextSocket.outputStream, Charsets.UTF_8))
        emitConnection("connected")
        ioExecutor.execute { readLoop(nextSocket) }
    }

    private fun readLoop(activeSocket: BluetoothSocket) {
        try {
            while (activeSocket.isConnected) {
                val line = reader?.readLine() ?: break
                if (line.isNotBlank()) emitMessage(line)
            }
        } catch (error: IOException) {
            emitError("CONNECTION_LOST", error.message ?: "Bluetooth connection lost.")
        } finally {
            disconnect(closeServer = false)
        }
    }

    @SuppressLint("MissingPermission")
    private fun startDiscovery() {
        val bluetoothAdapter = adapter ?: throw IllegalStateException("Bluetooth is not available.")
        if (!hasScanPermission()) throw SecurityException("Bluetooth scan permission is required.")
        registerDiscoveryReceiver()
        bluetoothAdapter.cancelDiscovery()
        emitBondedDevices()
        if (!bluetoothAdapter.startDiscovery()) {
            throw IllegalStateException("Unable to start Bluetooth discovery.")
        }
    }

    @SuppressLint("MissingPermission")
    private fun stopDiscovery() {
        if (hasScanPermission()) adapter?.cancelDiscovery()
    }

    @SuppressLint("MissingPermission")
    private fun pairedDevices(): List<Map<String, Any?>> {
        if (!hasConnectPermission()) return emptyList()
        return adapter?.bondedDevices?.map { it.toMap(bonded = true) }.orEmpty()
    }

    @SuppressLint("MissingPermission")
    private fun emitBondedDevices() {
        pairedDevices().forEach { emitDevice(it) }
    }

    private fun registerDiscoveryReceiver() {
        if (discoveryReceiver != null) return
        discoveryReceiver = object : BroadcastReceiver() {
            @SuppressLint("MissingPermission")
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    BluetoothDevice.ACTION_FOUND -> {
                        val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                        }
                        if (device != null && hasConnectPermission()) emitDevice(device.toMap())
                    }
                    BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> emitConnection("discoveryFinished")
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }
        activity.registerReceiver(discoveryReceiver, filter)
    }

    private fun sendRaw(packet: String) {
        ioExecutor.execute {
            try {
                val line = if (packet.endsWith("\n")) packet else "$packet\n"
                writer?.apply {
                    write(line)
                    flush()
                } ?: throw IOException("No active Bluetooth socket.")
            } catch (error: IOException) {
                emitError("SEND_FAILED", error.message ?: "Unable to send packet.")
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun makeDiscoverable() {
        val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
            putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
        }
        activity.startActivity(intent)
    }

    private fun disconnect(closeServer: Boolean = true) {
        runCatching { reader?.close() }
        runCatching { writer?.close() }
        runCatching { socket?.close() }
        reader = null
        writer = null
        socket = null
        if (closeServer) {
            runCatching { serverSocket?.close() }
            serverSocket = null
        }
        emitConnection("disconnected")
    }

    private fun dispose() {
        accepting.set(false)
        disconnect()
        stopDiscovery()
        discoveryReceiver?.let { runCatching { activity.unregisterReceiver(it) } }
        discoveryReceiver = null
        ioExecutor.shutdownNow()
    }

    private fun isBluetoothEnabled(): Boolean = adapter?.isEnabled == true

    private fun hasScanPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            hasPermission(Manifest.permission.BLUETOOTH_SCAN)
        } else {
            hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    private fun hasConnectPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            hasPermission(Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            true
        }
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
    }

    @SuppressLint("MissingPermission")
    private fun BluetoothDevice.toMap(bonded: Boolean = bondState == BluetoothDevice.BOND_BONDED): Map<String, Any?> {
        return mapOf(
            "name" to (name ?: "Unknown device"),
            "address" to address,
            "bonded" to bonded,
        )
    }

    private fun emitConnection(state: String) {
        activity.runOnUiThread { connectionSink?.success(state) }
    }

    private fun emitDevice(device: Map<String, Any?>) {
        activity.runOnUiThread { deviceSink?.success(device) }
    }

    private fun emitMessage(message: String) {
        activity.runOnUiThread { messageSink?.success(message) }
    }

    private fun emitError(code: String, message: String) {
        activity.runOnUiThread {
            errorSink?.success(mapOf("code" to code, "message" to message))
        }
    }
}


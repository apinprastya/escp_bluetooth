package com.lekapin.escpbluetooth;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.ParcelUuid;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** EscpBluetoothPlugin */
public class EscpBluetoothPlugin implements MethodCallHandler, PluginRegistry.ActivityResultListener {

  static final String TAG = "EscpBluetoothPlugin";
  private final Registrar registrar;
  private final MethodChannel channel;
  private UUID printerUUID = UUID
          .fromString("00001101-0000-1000-8000-00805F9B34FB");

  private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
    public void onReceive(Context context, Intent intent) {
      String action = intent.getAction();
      Log.d(TAG, action);
      if (BluetoothDevice.ACTION_FOUND.equals(action)) {
        BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
        device.fetchUuidsWithSdp();
        final ParcelUuid []uuids = device.getUuids();
        Log.d(TAG, "Bluetooth found " + device.getName() + " : " + device.getAddress() + " : " + uuids);
        if(uuids == null) return;
        if(device.getName() == null) return;
        for(int i = 0; i < uuids.length; i++) {
            Log.d(TAG, "Bluetooth UUID " + uuids[i].getUuid());
          if(uuids[i].getUuid().compareTo(printerUUID) == 0) {
            if(!mDevices.contains(device)) {
                mDevices.add(device);
              Map<String, Object> content = new HashMap<>();
              content.put("mac_address", device.getAddress());
              content.put("name", device.getName());
              channel.invokeMethod("deviceDiscovered", content);
            }
          }
        }
      } else if(BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
          channel.invokeMethod("discoverDone", null);
      }
    }
  };

  List<BluetoothDevice> mDevices = new ArrayList<>();
  BluetoothAdapter mBluetoothAdapter;
  BluetoothSocket mSocket;
  BluetoothDevice mDevice;
  OutputStream mOutputStream;
  InputStream mInputStream;

  EscpBluetoothPlugin(Registrar registrar, MethodChannel channel) {
    this.registrar = registrar;
    this.channel = channel;
    mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
    this.registrar.addActivityResultListener(this);
    if(mBluetoothAdapter != null) {
      Log.d(TAG, "Bluetooth available");
      IntentFilter filter = new IntentFilter(BluetoothDevice.ACTION_FOUND);
      filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
      filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
      registrar.activity().registerReceiver(mReceiver, filter);
    }
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.lekapin.escp_bluetooth");
    Log.d(TAG, "REGISTERING");
    channel.setMethodCallHandler(new EscpBluetoothPlugin(registrar, channel));
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if(call.method.equals("isOn")) {
      if(mBluetoothAdapter != null)
        result.success(mBluetoothAdapter.isEnabled());
      else
        result.error("EscpBluetoothPlugin", "Bluetooth not available", "Bluetooth not available");
    } else if(call.method.equals("turnOn")) {
      Log.d(TAG, "Enabling bluetooth");
      if(mBluetoothAdapter != null && !mBluetoothAdapter.isEnabled()) {
        Log.d(TAG, "Enabling bluetooth start Activity");
        Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
        registrar.activity().startActivityForResult(enableBtIntent, 0);
      } if(mBluetoothAdapter == null) {
        Log.e(TAG, "Bluetooth not available");
        result.error("EscpBluetoothPlugin", "Bluetooth not available", "Bluetooth not available");
      } else {
        result.success(true);
      }
    } else if(call.method.equals("scan")) {
      if(mBluetoothAdapter == null) {
        Log.e(TAG, "Bluetooth not available");
        result.error("EscpBluetoothPlugin", "Bluetooth not available", "Bluetooth not available");
      } else {
        if(!mBluetoothAdapter.isEnabled()) {
          Log.e(TAG, "Bluetooth is off");
          result.error("EscpBluetoothPlugin", "Bluetooth is Off", "Bluetooth is Off");
        } else {
          if(mBluetoothAdapter.isDiscovering()) {
              Log.d(TAG, "Bluetooth already discovering");
              mBluetoothAdapter.cancelDiscovery();
          }
          Log.d(TAG, "Bluetooth start dicovering");
          mBluetoothAdapter.startDiscovery();
        }
      }
    } else if(call.method.equals("scanBounded")) {
        Set<BluetoothDevice> devices = mBluetoothAdapter.getBondedDevices();
        List<Map<String, Object>> bt = new ArrayList<>();
        for (BluetoothDevice device : devices) {
            Log.d(TAG, "BLUETOOTH " + device.getName() + " : " + device.getAddress());
            Map<String, Object> content = new HashMap<>();
            content.put("name", device.getName());
            content.put("mac_address", device.getAddress());
            final ParcelUuid []uuids = device.getUuids();
            boolean found = false;
            for(int i = 0; i < uuids.length; i++) {
                Log.d(TAG, uuids[i].getUuid().toString());
                if(uuids[i].getUuid().compareTo(printerUUID) == 0) {
                    found = true;
                    break;
                }
            }
            if(found)
                bt.add(content);
        }
        result.success(bt);
    } else if(call.method.equals("connect")) {
        final String address = (String) call.arguments;
        Log.d(TAG, "Connect to device " + address);
        if (!mBluetoothAdapter.isEnabled()) {
            Log.e(TAG, "Connect: Bluetooth is off");
            result.error("EscpBluetoothPlugin", "Connect: Bluetooth is Off", "Connect: Bluetooth is Off");
        } else {
            mDevice = mBluetoothAdapter.getRemoteDevice(address);
            if(mSocket != null && mSocket.isConnected()) {
                result.success(true);
            } else if (mDevice == null) {
                Log.e(TAG, "Connect: device not available");
                result.error("EscpBluetoothPlugin", "Connect: device not available", "Connect: device not available");
            } else {
                mBluetoothAdapter.cancelDiscovery();
                try {
                    mSocket = mDevice.createRfcommSocketToServiceRecord(printerUUID);
                } catch (Exception e) {
                    Log.e(TAG, "Connect: " + e.getMessage());
                    result.error("EscpBluetoothPlugin", e.getMessage(), e.getMessage());
                }
                if (mSocket != null) {
                    try {
                        mSocket.connect();
                        mOutputStream = mSocket.getOutputStream();
                        Log.d(TAG, "Connected");
                    } catch (Exception e) {
                        Log.e(TAG, "Connect: " + e.getMessage());
                        result.error("EscpBluetoothPlugin", e.getMessage(), e.getMessage());
                    }
                }
                result.success(true);
            }
        }
    } else if(call.method.equals("disconnect")) {
        if (!mBluetoothAdapter.isEnabled()) {
            Log.e(TAG, "Disconnect: Bluetooth is off");
            result.error("EscpBluetoothPlugin", "Disconnect: Bluetooth is Off", "Disconnect: Bluetooth is Off");
        } else if(mSocket.isConnected()) {
            try {
                mSocket.close();
                Log.d(TAG, "Disconnected");
            } catch (Exception e) {
                Log.e(TAG, "Disconnect: " + e.getMessage());
                result.error("EscpBluetoothPlugin", e.getMessage(), e.getMessage());
            }
        }
    } else if(call.method.equals("printData")) {
        if(mSocket == null || (mSocket != null && !mSocket.isConnected())) {
            Log.e(TAG, "printData: print data");
            result.error("EscpBluetoothPlugin", "printData: Socket is not connected", "Socket is not connected");
        } else {
            try {
                mOutputStream.write((byte[]) call.arguments);
                result.success(true);
            } catch(Exception e) {
                Log.e(TAG, "printData: " + e.getMessage());
                result.error("EscpBluetoothPlugin", "printData: " + e.getMessage(), "printData: " + e.getMessage());
            }
        }
    } else {
      result.notImplemented();
    }
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent intent) {
    if(requestCode == 0) {
        channel.invokeMethod("turnOnStatus",resultCode == Activity.RESULT_OK);
      return true;
    }
    return false;
  }
}


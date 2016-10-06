import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;
import android.content.Intent;
import android.os.Handler;
import android.os.Parcelable;
import android.content.BroadcastReceiver;

import android.provider.Settings;
import android.util.Log;
import java.io.IOException;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import java.io.InputStream;
import java.io.OutputStream;

import org.apache.cordova.CallbackContext;

import java.util.*;


public class BluetoothClassicPlugin extends CordovaPlugin {

 public enum State {
  STATE_DISCONNECTED,
  STATE_CONNECTING,
  STATE_CONNECTED,
  STATE_TEST
 }

 private class ConnectionData {

  public BluetoothDevice mDevice;
  public BluetoothSocket mSocket;
  public InputStream mInputStream;
  public OutputStream mOutputStream;
  public CallbackContext mConnectCallback;

  public String macAddress;

  public State mState;

  public ConnectionData() {
   mState = State.STATE_CONNECTING;
  }

 }

 interface connectionCallback {
  void success();
 }


 private class ConnectThread extends Thread {

  private /*final*/ BluetoothSocket mmSocket;
  private final BluetoothDevice mmDevice;
  private static final String CONNECT = "connect";
  private static final String WRITE = "write";
  private static final String READ = "read";
  private static final String DISCONNECT = "disconnect";
  private static final String IS_CONNECTED = "isConnected";
  private static final String CLEAR_CACHE = "clearCache";
  public CallbackContext mConnectCallback;
  public String mSuccessMethod;
  public Object mSpawner;

  private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
   @Override
   public void onReceive(Context context, Intent intent) {
    BluetoothDevice device = intent.getParcelableExtra("android.bluetooth.device.extra.DEVICE");
    Parcelable[] uuidExtra = intent.getParcelableArrayExtra("android.bluetooth.device.extra.UUID");

    System.out.format("Received some shit in the receiver: %d %n", uuidExtra.length);
   }
  };


  public ConnectThread(BluetoothDevice device, CallbackContext cb, Object spawner, String successMethod) {

   mmDevice = device;
   mConnectCallback = cb;
   mSuccessMethod = successMethod;
   mSpawner = spawner;
  }

  public void run() {
   // This sets up a listener for bluetooth actions, we don't use it for much
   /*String action = "android.bleutooth.device.action.UUID";
   IntentFilter filter = new IntentFilter(action);
   this.cordova.getActivity().getApplicationContext().registerReceiver(mReceiver, filter);*/


   ConnectionData theConnection = new ConnectionData();
   theConnection.mDevice = mmDevice;
   try {

    System.out.println("Retrieving socket 1");
    theConnection.mSocket = theConnection.mDevice.createRfcommSocketToServiceRecord(SERVICE_UUID);

   } catch (Exception e) {

    System.out.format("Failed to retrieve Socket 1 with SERVICE_UUID: %s", SERVICE_UUID);
    e.printStackTrace();
    String message = String.format("failed to connect to bluetooth classic device: %s");
    JSONObject json = new JSONObject();
    //json.put("message", message);
    //callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
    System.out.flush();

    try {
     String reportResult = "failure";
     mSpawner.getClass().getMethod(mSuccessMethod, String.class, ConnectionData.class).invoke(mSpawner, reportResult, null);
    } catch (Exception callbackE) {
     // If it fails, write the error message to screen
     callbackE.printStackTrace();
    }

    return;

   }

   if (theConnection.mSocket == null) {
    System.out.println("Socket still null. Returning...");
    String message = String.format("failed to connect to bluetooth classic device");
    JSONObject json = new JSONObject();
    //json.put("message", message);
    //callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
    System.out.flush();
    try {
     String reportResult = "failure";
     mSpawner.getClass().getMethod(mSuccessMethod, String.class, ConnectionData.class).invoke(mSpawner, reportResult, null);
    } catch (Exception callbackE) {
     // If it fails, write the error message to screen
     callbackE.printStackTrace();
    }
    return;
   }

   try {
    System.out.format("Attemping to connect to bluetooth classic device");
    theConnection.mSocket.connect();
    theConnection.mOutputStream = theConnection.mSocket.getOutputStream();
    theConnection.mInputStream = theConnection.mSocket.getInputStream();
    theConnection.mConnectCallback = mConnectCallback;
    //theConnection.mState = mState.STATE_CONNECTED;
    theConnection.macAddress = theConnection.mDevice.getAddress();

    //

    String message = String.format("successfully connected to bluetooth classic device");
    JSONObject json = new JSONObject();
    System.out.flush();
    try {
     String reportResult = "success";
     mSpawner.getClass().getMethod(mSuccessMethod, String.class, ConnectionData.class).invoke(mSpawner, reportResult, theConnection);
    } catch (Exception callbackE) {
     // If it fails, write the error message to screen
     callbackE.printStackTrace();
    }

   } catch (IOException e) {
    e.printStackTrace();

    try {
     System.out.format("Classic connect attempt 1 failed. Entering fallback. Attempting to connect to device");
     theConnection.mSocket = (BluetoothSocket) theConnection.mDevice.getClass().getMethod("createRfcommSocket", new Class[] {
      int.class
     }).invoke(theConnection.mDevice, 1);
     mmSocket.connect();
    } catch (Exception e2) {
     try {
      theConnection.mSocket.close();
      theConnection.mSocket = null;
      //theConnection.mState = STATE_DISCONNECTED;
     } catch (IOException e3) {
      e3.printStackTrace();
     }

     System.out.flush();
     try {
      String reportResult = "failure";
      mSpawner.getClass().getMethod(mSuccessMethod, String.class, ConnectionData.class).invoke(mSpawner, reportResult, null);
     } catch (Exception callbackE) {
      // If it fails, write the error message to screen
      callbackE.printStackTrace();
     }

    }
   }

  }

  public void cancel() {
   try {
    mmSocket.close();
   } catch (IOException e) {}
  }
 }

 // actions
 private static final String CONNECT = "connect";
 private static final String WRITE = "write";
 private static final String READ = "read";
 private static final String DISCONNECT = "disconnect";
 private static final String IS_CONNECTED = "isConnected";
 private static final String CLEAR_CACHE = "clearCache";

 private List < ConnectionData > connectionsList = new ArrayList < ConnectionData > ();

 private byte[] rxBuffer = new byte[1024 * 25];
 private byte[] jpgCpy;

 private BluetoothAdapter bluetoothAdapter;
 private static final String TAG = "BluetoothClassicService";

 private static final UUID SERVICE_UUID =
  UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

 @Override
 public void onDestroy() {
  super.onDestroy();
 }
 private ConnectThread mConnectThread;


 public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
  if (bluetoothAdapter == null) {
   bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
  }

  boolean validAction = true;
  if (action.equals(CONNECT)) {
   connect(args, callbackContext);
  } else if (action.equals(READ)) {
   read(args, callbackContext);
  } else if (action.equals(WRITE)) {
   write(args, callbackContext);
  } else if (action.equals(DISCONNECT)) {
   disconnect(args, callbackContext);
  } else if (action.equals(IS_CONNECTED)) {
   isConnected(args, callbackContext);
  } else if (action.equals(CLEAR_CACHE)) {
   clearCache(args, callbackContext);
  } else {
   validAction = false;
   callbackContext.error("Invalid command");
  }
  return validAction;
 }

 private void resetConnection(CordovaArgs args) throws JSONException {
  String macAddress = args.getString(0);
  System.out.println("Restting Connections");
  ConnectionData theConnection = getConnection(macAddress);
  if (theConnection != null) {
   System.out.println("Found a connection. Closing sockets");

   if (theConnection.mInputStream != null) {
    try {
     theConnection.mInputStream.close();
    } catch (Exception e) {}
    theConnection.mInputStream = null;
   }

   if (theConnection.mOutputStream != null) {
    try {
     theConnection.mOutputStream.close();
    } catch (Exception e) {}
    theConnection.mOutputStream = null;
   }

   if (theConnection.mSocket != null) {
    try {
     theConnection.mSocket.close();
    } catch (Exception e) {}
    theConnection.mSocket = null;
   }
  }

 }

 private void clearCache(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
  try {
   bluetoothAdapter.disable();
   Thread.sleep(100);
  } catch (final InterruptedException e) {}

  try {
   bluetoothAdapter.enable();
   Thread.sleep(100);
  } catch (final InterruptedException e) {}


  if (!bluetoothAdapter.isEnabled()) {
   bluetoothAdapter.enable();
   try {
    Thread.sleep(1000);
   } catch (InterruptedException e) {}
  }

  String message = String.format("Successfully reset bluetooth cache");
  JSONObject json = new JSONObject();
  try {
   json.put("message", message);
   callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));
  } catch (JSONException err2) {
   err2.printStackTrace();
  }
 }

 private void write(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
  String macAddress = args.getString(0);

  ConnectionData theConnection = getConnection(macAddress);

  // check to make sure theConnection is not null
  if (theConnection == null) {
   String message = "failed to locate the bluetooth device.";
   JSONObject json = new JSONObject();
   try {
    json.put("message", message);
    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
    return;
   } catch (JSONException e) {
    e.printStackTrace();
    return;
   }
  }

  if (theConnection.mOutputStream == null) {
   String message = "Bluetooth device has an invalid output stream.";
   JSONObject json = new JSONObject();
   try {
    json.put("message", message);
    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
    return;
   } catch (JSONException e) {
    e.printStackTrace();
    return;
   }
  }

  try {
   // theConnection.mOutputStream.write(out);
   String message = "successfully wrote to connected bluetooth device.";
   JSONObject json = new JSONObject();
   try {
    json.put("message", message);
    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));
    return;
   } catch (JSONException err2) {
    err2.printStackTrace();
   }
  } catch (Exception e) {
   e.printStackTrace();

   theConnection.mState = State.STATE_DISCONNECTED;
   String message = "failed to connect to write to connected bluetooth device.";
   JSONObject json = new JSONObject();
   try {
    json.put("message", message);
    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
    return;
   } catch (JSONException err2) {
    err2.printStackTrace();
   }
  }
 }

 private void disconnect(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
  String macAddress = args.getString(0);

  ConnectionData theConnection = getConnection(macAddress);

  // check to make sure theConnection is not null
  if (theConnection == null) {

  }

  cmdDisconnect(theConnection);

  try {
   String message = String.format("Successfully disconnected to bluetooth classic device.");
   JSONObject json = new JSONObject();
   json.put("message", message);
   callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));
  } catch (Exception e) {
   callbackContext.success();
  }
 }

 public void connectSuccess(String result, ConnectionData newConnection) {
  if (result == "success") {
   newConnection.mState = State.STATE_CONNECTED;
   connectionsList.add(newConnection);
   String message = String.format("Successfully connected to bluetooth classic device.");
   System.out.println("Connection Succeeded");
   System.out.flush();


   try {
    JSONObject json = new JSONObject();
    json.put("message", message);
    newConnection.mConnectCallback.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));
   } catch (Exception e) {
    // If it fails, write the error message to screen
    e.printStackTrace();
   }
  } else {
   newConnection.mState = State.STATE_DISCONNECTED;
   System.out.println("Connection Failed");
   System.out.flush();


   String message = String.format("Was unable to connect to bluetooth classic device.");
   JSONObject json = new JSONObject();
   try {
    json.put("message", message);
    newConnection.mConnectCallback.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));
   } catch (Exception e) {
    // If it fails, write the error message to screen
    e.printStackTrace();
   }
  }
 }

 private void connect(CordovaArgs args, CallbackContext callbackContext) throws JSONException {

  String macAddress = args.getString(0);

  BluetoothDevice mDevice = bluetoothAdapter.getRemoteDevice(macAddress);
  System.out.format("Got Remote Device %s%n", mDevice.getName());
  System.out.format("%s%n", mDevice.toString());
  mConnectThread = new ConnectThread(mDevice, callbackContext, this, "connectSuccess");
  mConnectThread.start();



 }

 private void cmdDisconnect(ConnectionData theConnection) {
  if (theConnection.mState == null || theConnection.mState != State.STATE_DISCONNECTED) {
   try {
    theConnection.mOutputStream.close();
   } catch (Exception e) {}
   try {
    theConnection.mInputStream.close();
   } catch (Exception e) {}
   try {
    theConnection.mSocket.close();
   } catch (Exception e) {}
   theConnection.mState = State.STATE_DISCONNECTED;
   theConnection.mInputStream = null;
   theConnection.mOutputStream = null;
   theConnection.mSocket = null;
   connectionsList.remove(theConnection);
  }
 }

 private void read(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
  try {

   String macAddress = args.getString(0);

   ConnectionData theConnection = getConnection(macAddress);

   // check to make sure theConnection is not null
   if (theConnection == null) {
    String message = "failed to locate the bluetooth device.";
    JSONObject json = new JSONObject();
    try {
     json.put("message", message);
     callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
     System.out.flush();
     return;
    } catch (JSONException e) {
     e.printStackTrace();
     return;
    }
   }

   System.out.format("Bytes available to be read: %d\n", theConnection.mInputStream.available());
   int available = theConnection.mInputStream.available();
   if (available > 0) {
    int length = theConnection.mInputStream.read(rxBuffer);
    jpgCpy = new byte[length];

    for (int i = 0; i < length; i++) {
     jpgCpy[i] = rxBuffer[i];
    }

    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, jpgCpy));
    System.out.flush();
   } else {
    String message = String.format("failed to read from device. No data to be read.");
    JSONObject json = new JSONObject();
    json.put("message", message);
    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
    System.out.flush();
   }
  } catch (IOException err) {
   err.printStackTrace();
   String message = String.format("failed to read from device");
   JSONObject json = new JSONObject();
   json.put("message", message);
   callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
   System.out.flush();
  }

 }

 private void isConnected(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
  String macAddress = args.getString(0);
  ConnectionData theConnection = getConnection(macAddress);

  if (theConnection == null || theConnection.mState != State.STATE_CONNECTED) {
   System.out.format("Device %s is not connected\n", macAddress);
   String message = "failed to locate the bluetooth device.";
   JSONObject json = new JSONObject();
   try {
    json.put("message", message);
    callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
    System.out.flush();
    return;
   } catch (JSONException e) {
    e.printStackTrace();
    return;
   }
  }

  try {
   System.out.format("Device %s has good connection\n", macAddress);
   String message = String.format("Requested device is connected");
   JSONObject json = new JSONObject();
   json.put("message", message);
   callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));
   System.out.flush();
  } catch (JSONException e) {
   e.printStackTrace();
   return;
  }

 }

 private ConnectionData getConnection(String address) {
  for (int i = 0; i < connectionsList.size(); i++) {
   ConnectionData cd = connectionsList.get(i);
   if (cd.macAddress.equals(address)) {
    return cd;
   }
  }

  return null;
 }


}

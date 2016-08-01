package BTCPlugin;

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

import java.util.*;

public class BluetoothClassicPlugin extends CordovaPlugin {

    // actions
    private static final String CONNECT = "connect";
    private static final String WRITE = "write";
    private static final String READ = "read";
    private static final String DISCONNECT = "disconnect";
    private static final String IS_CONNECTED = "isConnected";

    private List<ConnectionData> connectionsList;

    private int mState;
    private BluetoothSocket mSocket;
    private OutputStream mOutputStream;
    private InputStream mInputStream;

    private byte[] rxBuffer = new byte[1024*25];
    private byte[] jpgCpy;

    // callbacks
    private CallbackContext connectCallback;
    private CallbackContext disconnectCallback;

    private BluetoothAdapter bluetoothAdapter;

    private static final UUID SERVICE_UUID =
            UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

    @Override
    public void onDestroy() {
          cmdDisconnect();
          super.onDestroy();
    }

    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
          BluetoothDevice device = intent.getParcelableExtra("android.bluetooth.device.extra.DEVICE");
          Parcelable[] uuidExtra = intent.getParcelableArrayExtra("android.bluetooth.device.extra.UUID");

          System.out.format("Received some shit in the receiver: %d %n", uuidExtra.length);
        }
    };

    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
      if (bluetoothAdapter == null) {
            bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
      }

      boolean validAction = true;
      if (action.equals(CONNECT)) {
        connect(args, callbackContext);
      }
      else if (action.equals(WRITE)) {
        byte[] data = args.getArrayBuffer(0);
        write(data, callbackContext);
      }
      else if (action.equals(READ)) {
        read(callbackContext);
      }
      else if (action.equals(DISCONNECT)){
        disconnect(callbackContext);
      }
      else if (action.equals(IS_CONNECTED)) {

            if (mState == STATE_CONNECTED) {
                callbackContext.success();
            } else {
                callbackContext.error("Not connected.");
            }

        }
      else{
        validAction = false;
      }
      return validAction;
    }

    private void write(byte[] out, CallbackContext callbackContext) throws JSONException {
      if (mOutputStream == null) {
            return;
        }
        try {
            mOutputStream.write(out);
            String message = "successfully wrote to connected bluetooth device.";
            JSONObject json = new JSONObject();
            json.put("message", message);
            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));
        } catch (IOException e) {
            e.printStackTrace();

            closeSocket();
            mState = STATE_DISCONNECTED;
              String message = "failed to connect to write to connected bluetooth device.";
              JSONObject json = new JSONObject();
              try{
                json.put("message", message);
                callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
              }

            catch(JSONException err2){
              err2.printStackTrace();
            }
        }
    }

    private void disconnect(CallbackContext callbackContext) throws JSONException {
      cmdDisconnect();

      try {
        String message = String.format("Successfully disconnected to bluetooth classic device.");
        JSONObject json = new JSONObject();
        json.put("message", message);
        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));
      } catch (Exception e){
        callbackContext.success();
      }
    }

    private void connect(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
      if (mState == STATE_DISCONNECTED) {

        String macAddress = args.getString(0);
        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);

        System.out.format("Got Remote Device %s%n", device.getName());
        System.out.format("%s%n", device.toString());

        String action = "android.bleutooth.device.action.UUID";
        IntentFilter filter = new IntentFilter(action);
        this.cordova.getActivity().getApplicationContext().registerReceiver(mReceiver, filter);

        try {
          System.out.println("Retrieving socket 1");
            mSocket = device.createRfcommSocketToServiceRecord(SERVICE_UUID);

        } catch (Exception e){
          System.out.format("Failed to retrieve Socket 1 with SERVICE_UUID: %s", SERVICE_UUID);
          e.printStackTrace();
          String message = String.format("failed to connect to bluetooth classic device: %s", macAddress);
          JSONObject json = new JSONObject();
          json.put("message", message);
          callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
          return;
        }

        if(mSocket == null){
          System.out.println("Socket still null. Returning...");
          String message = String.format("failed to connect to bluetooth classic device: %s", macAddress);
          JSONObject json = new JSONObject();
          json.put("message", message);
          callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
          return;
        }

        mState = STATE_CONNECTING;
        try {
              System.out.format("Attemping to connect to bluetooth classic device: %s", macAddress);
              mSocket.connect();
              mOutputStream = mSocket.getOutputStream();
              mInputStream = mSocket.getInputStream();
              mState = STATE_CONNECTED;
              String message = String.format("successfully connected to bluetooth classic device: %s", macAddress);
              JSONObject json = new JSONObject();
              json.put("message", message);
              callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, json));

          } catch (IOException e) {
              e.printStackTrace();

              try {
                System.out.format("Classic connect attempt 1 failed. Entering fallback. Attempting to connect to device: %s", macAddress);
                mSocket =(BluetoothSocket) device.getClass().getMethod("createRfcommSocket", new Class[] {int.class}).invoke(device,1);
                mSocket.connect();
              } catch (Exception e2){
              closeSocket();
              mState = STATE_DISCONNECTED;
              String message = String.format("failed to connect to bluetooth classic device: %s", macAddress);
              JSONObject json = new JSONObject();
              json.put("message", message);
              callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
            }
          }
        }
    }

    private void cmdDisconnect() {
        if (mState != STATE_DISCONNECTED) {
            try {mOutputStream.close();} catch (Exception e) {}
            try {mInputStream.close();} catch (Exception e) {}
            closeSocket();
            mState = STATE_DISCONNECTED;
        }
    }

    private void closeSocket() {
        if (mSocket != null) {
            try {
                mSocket.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
            mSocket = null;
        }
    }

    private void read(CallbackContext callbackContext) throws JSONException {
      try{


        System.out.format("Bytes available to be read: %d\n", mInputStream.available());
        int length = mInputStream.read(rxBuffer);
        jpgCpy = new byte[length];

        for(int i = 0; i < length; i++){
          jpgCpy[i] = rxBuffer[i];
        }

        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, jpgCpy));
        }
        catch(IOException err){
          err.printStackTrace();
          String message = String.format("failed to read from device");
          JSONObject json = new JSONObject();
          json.put("message", message);
          callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
        }
    }

}

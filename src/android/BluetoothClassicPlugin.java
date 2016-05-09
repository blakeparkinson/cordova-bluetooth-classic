
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.bluetooth.BluetoothSocket;
import android.content.IntentFilter;
import android.content.Intent;
import android.os.Handler;

import android.provider.Settings;
import android.util.Log;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.*;
import java.util.Set;

public class BluetoothClassicPlugin extends CordovaPlugin {

    // actions
    private static final String CONNECT = "connect";
    private static final String WRITE = "write";
    private static final String READ = "read";


    private static final int STATE_DISCONNECTED = 0;
    private static final int STATE_CONNECTING = 1;
    private static final int STATE_CONNECTED = 2;
    private static final int STATE_TEST = 3;
    private int mState;
    private BluetoothSocket mSocket;
    private OutputStream mOutputStream;
    private InputStream mInputStream;

    private byte[] rxBuffer = new byte[1024*25];

    // callbacks
    private CallbackContext connectCallback;
    private BluetoothAdapter bluetoothAdapter;

    private static final UUID SERVICE_UUID =
            UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

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

    private void connect(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
      if (mState == STATE_DISCONNECTED) {

        String macAddress = args.getString(0);
        Log.v("macAddress", macAddress);
        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);

        try {
          mSocket = device.createRfcommSocketToServiceRecord(device.getUuids()[0].getUuid());
        } catch (Exception e){
          String message = String.format("failed to connect to bluetooth classic device: %s", macAddress);
          JSONObject json = new JSONObject();
          json.put("message", message);
          callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, json));
        }



        mState = STATE_CONNECTING;
        try {
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

        int length = mInputStream.read(rxBuffer);
          /*JSONObject json = new JSONObject();
          json.put("data", rxBuffer);
          json.put("length", length);*/
          callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, rxBuffer));
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

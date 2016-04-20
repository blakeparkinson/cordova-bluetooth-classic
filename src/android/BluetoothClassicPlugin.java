
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;
import android.content.Intent;
import android.os.Handler;

import android.provider.Settings;
import android.util.Log;
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
    // callbacks
    private CallbackContext connectCallback;

    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
      if (action.equals(CONNECT)) {
        connect(args, callbackContext);
      }
    }

    private void connect(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        String macAddress = args.getString(0);
        //BluetoothDevice device = bluetoothAdapter.getRemoteDevice(macAddress);

    }

}

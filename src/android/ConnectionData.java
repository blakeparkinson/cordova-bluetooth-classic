package BTCPlugin;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import java.io.InputStream;
import java.io.OutputStream;

import org.apache.cordova.CallbackContext;

public class ConnectionData {

  public BluetoothDevice  mDevice;
  public BluetoothSocket  mSocket;
  public InputStream      mInputStream;
  public OutputStream     mOutputStream;

  public CallbackContext  mConnectCallback;

  public String macAddress;

  public State mState;

  public ConnectionData(){
    mState = STATE_CONNECTING;
  }

}

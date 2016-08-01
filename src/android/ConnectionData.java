package BTCPlugin;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import java.io.InputStream;
import java.io.OutputStream;

import org.apache.cordova.CallbackContext;

private static final int STATE_DISCONNECTED = 0;
private static final int STATE_CONNECTING = 1;
private static final int STATE_CONNECTED = 2;
private static final int STATE_TEST = 3;

public class ConnectionData {

  public BluetoothDevice  mDevice;
  public BluetoothSocket  mSocket;
  public InputStream      mInputStream;
  public OutputStream     mOutputStream;

  public CallbackContext  mConnectCallback;
  
  public String macAddress;

  public int mState;

  public ConnectionData(){
    mState = STATE_CONNECTING;
  }

}

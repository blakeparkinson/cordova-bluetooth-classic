package BTCPlugin;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import java.io.InputStream;
import java.io.OutputStream;

import org.apache.cordova.CallbackContext;

public class ConnectionData {

  public BluetoothSocket  mSocket;
  public InputStream      mInputStream;
  public OutputStream     mOutputStream;
  public BluetoothDevice  mDevice;

  public CallbackContext  mConnectCallback;
  public CallbackContext  mDisconnectCallback;

  private static final int STATE_DISCONNECTED = 0;
  private static final int STATE_CONNECTING = 1;
  private static final int STATE_CONNECTED = 2;
  private static final int STATE_TEST = 3;

  public ConnectionData(){

  }

  public int getState(){
    return mState;
  }

}

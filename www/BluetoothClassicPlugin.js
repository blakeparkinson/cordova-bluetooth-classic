"use strict";

module.exports = {

  connect: function(id, success, failure) {
    console.log('Connecting over BTClassic to Device with ID: '+id);
    cordova.exec(success, failure, 'BluetoothClassicPlugin', 'connect', [id]);
  },


  // This is unsuported as we do not use this anywhere.
  // all the wiring is setup to make implementation quick
  // if and when it is needed
  write: function(data, id, success, failure) {
    // convert to ArrayBuffer
    if (typeof data === 'string') {
      data = stringToArrayBuffer(data);
    } else if (data instanceof Array) {
      // assuming array of UNSIGNED BYTES
      data = new Uint8Array(data).buffer;
    } else if (data instanceof Uint8Array) {
      data = data.buffer;
    }

    cordova.exec(success, failure, "BluetoothClassicPlugin", "write", [id, data]);
  },

  read: function(id, success, failure) {
    console.log('Reading data from device: '+id);
    cordova.exec(success, failure, "BluetoothClassicPlugin", "read", [id]);
  },

  // Disconnect does not really work as intended on iOS due to the way GC is handled
  // Its more of a polite 'I am done with this, thanks' than a closure of the phy
  disconnect: function(success, failure){
    cordova.exec(success, failure, "BluetoothClassicPlugin", "disconnect", [id]);
  },

  isConnected: function (id, success, failure) {
    cordova.exec(success, failure, "BluetoothClassicPlugin", "isConnected", [id]);
  }
};

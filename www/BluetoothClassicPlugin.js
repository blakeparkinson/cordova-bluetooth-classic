"use strict";

module.exports = {

  connect: function(id, success, failure) {
    console.log('Connecting over BTClassic to Device with ID: '+id);
    cordova.exec(success, failure, 'BluetoothClassicPlugin', 'connect', [id]);
  },

  write: function(data, success, failure) {
    // convert to ArrayBuffer
    if (typeof data === 'string') {
      data = stringToArrayBuffer(data);
    } else if (data instanceof Array) {
      // assuming array of UNSIGNED BYTES
      data = new Uint8Array(data).buffer;
    } else if (data instanceof Uint8Array) {
      data = data.buffer;
    }

    cordova.exec(success, failure, "BluetoothClassicPlugin", "write", [data]);
  },

  read: function(id, success, failure) {
    console.log('Reading data from device: '+id);
    cordova.exec(success, failure, "BluetoothClassicPlugin", "read", [id]);
  },

  disconnect: function(success, failure){
    cordova.exec(success, failure, "BluetoothClassicPlugin", "disconnect", []);
  },
  isConnected: function (success, failure) {
    cordova.exec(success, failure, "BluetoothClassicPlugin", "isConnected", []);
  }
};

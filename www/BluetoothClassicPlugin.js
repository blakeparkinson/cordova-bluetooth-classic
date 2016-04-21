"use strict";

module.exports = {

  connect: function(id, success, failure) {
    console.log('made it');
    cordova.exec(success, failure, 'BluetoothClassicPlugin', 'connect', [id]);
  },
  write: function(data, success, failure) {
    // convert to ArrayBuffer
    if (typeof data === 'string') {
      data = stringToArrayBuffer(data);
    } else if (data instanceof Array) {
      // assuming array of interger
      data = new Uint8Array(data).buffer;
    } else if (data instanceof Uint8Array) {
      data = data.buffer;
    }

    cordova.exec(success, failure, "BluetoothClassicPlugin", "write", [data]);
  },

  read: function(success, failure) {
    cordova.exec(success, failure, "BluetoothClassicPlugin", "read", []);
  }
};

"use strict";

module.exports = {

    connect: function (id, success, failure) {
      console.log('made it');
      cordova.exec(success, failure, 'BluetoothClassic', 'connect', [id]);
    }
};

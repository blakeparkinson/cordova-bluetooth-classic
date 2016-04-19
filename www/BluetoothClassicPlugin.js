"use strict";

module.exports = {

    connect: function (id, success, failure) {
      cordova.exec(success, failure, 'BluetoothClassic', 'connect', [id]);
    }
};

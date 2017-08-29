var exec = require('cordova/exec');

exports.list = function(arg0, success, error) {
    exec(success, error, "PhonebookContacts", "list", [arg0]);
};

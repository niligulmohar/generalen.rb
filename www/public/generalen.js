/* -*- coding:iso-8859-1 -*- */

var G = {
    requests: {count: 0, pending:0, consecutive_failures: 0},
    start: function () {
	var d = loadJSONDoc('/aja/reset/');
	d.addCallbacks(G.listen, G.aja_error);
    },
    aja_error: function (err) {
	alert('Fel: ' + err);
    },
    listen: function (data) {
	var d = loadJSONDoc('/aja/');
	d.addCallbacks(G.recieve, G.listen_failure);
    },
    recieve: function (data) {
	G.handle_response(data);
	if (G.requests.consecutive_failures < 10) {
	    G.listen();
	}
	else {
	    G.error_message('Generalen är på väg ner ...');
	    //G.state(-1);
	}
    },
    listen_failure: function (err) {
	alert('Ett fel uppstod i "listen"! ' + err);
	AK.listen();
    },
    handle_response: function (data) {
    },
    login_request: function (data) {
    }
};

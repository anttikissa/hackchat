var newNick, ping, show, socket;

ping = function() {
  return socket.emit('ping', {
    ts: new Date().getTime()
  });
};

newNick = function(newNick) {
  return socket.emit('nick', {
    newNick: {
      newNick: newNick
    }
  });
};

show = function(msg) {
  return $('body').append("<p>" + msg + "</p>");
};

$(function() {
  $('body').append('<p>Hello from coffee</p>');
  $('#ping').click(function() {
    return ping();
  });
  $('#newNick').click(function() {
    return newNick($('#nick'));
  });
  socket.on('connect', function() {
    return ping();
  });
  return socket.on('pong', function(data) {
    var backThen, now;
    backThen = data.ts;
    now = new Date().getTime();
    return show("PONG " + (JSON.stringify(data)) + ", roundtrip " + (now - backThen) + " ms");
  });
});

socket = io.connect();

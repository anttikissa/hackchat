var ping, socket;

ping = function() {
  return socket.emit('ping', {
    ts: new Date().getTime()
  });
};

$(function() {
  $('body').append('<p>Hello from coffee</p>');
  $('button').click(function() {
    return ping();
  });
  socket.on('connect', function() {
    return ping();
  });
  return socket.on('pong', function(data) {
    var backThen, now;
    backThen = data.ts;
    now = new Date().getTime();
    return $('body').append("<p>PONG " + (JSON.stringify(data)) + ", roundtrip " + (now - backThen) + " ms");
  });
});

socket = io.connect();

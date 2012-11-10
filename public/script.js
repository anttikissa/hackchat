var socket;

$(function() {
  $('body').append('<p>Hello from coffee</p>');
  socket.on('connect', function() {
    return socket.emit('ping', {
      ts: new Date().getTime()
    });
  });
  return socket.on('pong', function(data) {
    return $('body').append("<p>PONG " + (JSON.stringify(data)));
  });
});

socket = io.connect();

var escapeHtml, newNick, ping, show, socket;

escapeHtml = function(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
};

ping = function() {
  return socket.emit('ping', {
    ts: new Date().getTime()
  });
};

newNick = function(newNick) {
  return socket.emit('newNick', {
    newNick: newNick
  });
};

show = function(msg) {
  return $('body').append("<p>" + (escapeHtml(msg)) + "</p>");
};

$(function() {
  $('body').append('<p>Hello from coffee</p>');
  $('#ping').click(function() {
    return ping();
  });
  $('#newNick').click(function() {
    var nick;
    console.log("newNick");
    nick = $('#nick').val();
    console.log("change to " + nick);
    return newNick(nick);
  });
  socket.on('connect', function() {
    return ping();
  });
  socket.on('pong', function(data) {
    var backThen, now;
    backThen = data.ts;
    now = new Date().getTime();
    return show("PONG " + (JSON.stringify(data)) + ", roundtrip " + (now - backThen) + " ms");
  });
  socket.on('newNick', function(_arg) {
    var newNick;
    newNick = _arg.newNick;
    show("Nick changed to " + newNick);
    return $('.mynick').html(newNick);
  });
  return socket.on('msg', function(_arg) {
    var from, msg;
    from = _arg.from, msg = _arg.msg;
    return show("<" + from + "> " + msg);
  });
});

socket = io.connect();

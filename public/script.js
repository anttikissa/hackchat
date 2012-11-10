var escapeHtml, join, mynick, newNick, ping, say, show, socket;

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

join = function(channel) {
  return socket.emit('join', {
    channel: channel
  });
};

say = function(channel, msg) {
  return socket.emit('say', {
    channel: channel,
    msg: msg
  });
};

show = function(msg) {
  return $('.chat').append("<p>" + (escapeHtml(msg)) + "</p>");
};

mynick = null;

$(function() {
  mynick = $('.mynick').html();
  $('#ping').click(function() {
    return ping();
  });
  $('#nick').change(function() {
    return newNick($('#nick').val());
  });
  $('#channel').change(function() {
    return join($('#channel').val());
  });
  $('#msg').change(function() {
    return say($('#sayChannel').val(), $('#msg').val());
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
    $('.mynick').html(newNick);
    return mynick = newNick;
  });
  socket.on('error', function(_arg) {
    var msg;
    msg = _arg.msg;
    return show("*** " + msg);
  });
  socket.on('msg', function(_arg) {
    var from, msg;
    from = _arg.from, msg = _arg.msg;
    return show("<" + from + "> " + msg);
  });
  socket.on('join', function(_arg) {
    var channel, nick;
    nick = _arg.nick, channel = _arg.channel;
    show("*** " + nick + " has joined channel #" + channel + ".");
    if (nick === mynick) {
      return $('#sayChannel').val(channel);
    }
  });
  socket.on('say', function(_arg) {
    var channel, msg, nick;
    nick = _arg.nick, channel = _arg.channel, msg = _arg.msg;
    return show("<" + nick + " #" + channel + "> " + msg);
  });
  return $('#cmd').focus();
});

socket = io.connect();

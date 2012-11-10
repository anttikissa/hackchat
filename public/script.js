var escapeHtml, execute, isCommand, join, mynick, newNick, parseCommand, ping, say, show, socket,
  __slice = [].slice;

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

isCommand = function(cmd) {
  return cmd.match(/^\//);
};

parseCommand = function(cmd) {
  var args, command, _ref;
  _ref = cmd.split(/\s+/), command = _ref[0], args = 2 <= _ref.length ? __slice.call(_ref, 1) : [];
  if (command === '/') {
    return {
      command: 'say',
      args: cmd.replace(/^\/\s+/, '')
    };
  } else {
    return {
      command: command.replace(/^\//, ''),
      args: args
    };
  }
};

execute = function(cmd) {
  var args, command, _ref, _ref1;
  if (isCommand(cmd)) {
    _ref = parseCommand(cmd), command = _ref.command, args = _ref.args;
  } else {
    _ref1 = {
      command: 'say',
      args: cmd
    }, command = _ref1.command, args = _ref1.args;
  }
  console.log("COMMAND " + command + ".");
  return console.log("ARGS " + (JSON.stringify(args)) + ".");
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
  $('#cmd').focus();
  return $('#cmd').keypress(function(event) {
    var cmd;
    if (event.keyCode === 13) {
      cmd = $(event.target).val();
      execute(cmd);
      return $(event.target).val('');
    }
  });
});

socket = io.connect();

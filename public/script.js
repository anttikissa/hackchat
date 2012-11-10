var escapeHtml, execute, help, isCommand, join, mychannel, mynick, names, newNick, parseCommand, ping, sanitize, say, show, socket,
  __slice = [].slice;

escapeHtml = function(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
};

sanitize = function(channel) {
  return channel.replace(/^#+/, '');
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
  channel = sanitize(channel);
  return socket.emit('join', {
    channel: channel
  });
};

names = function(channel) {
  channel = sanitize(channel);
  return socket.emit('names', {
    channel: channel
  });
};

help = function(help) {
  show("*** Available commands:");
  show("*** /nick <nick> - change nick.");
  show("*** /say <message> - say on current channel.");
  show("*** /join <channel> - join a channel. Alias: /j");
  show("*** /names [<channel>] - show who's on a channel");
  show("*** /help - here we are. Alias: /h");
  return show("*** /ping - ping the server.");
};

say = function(channel, msg) {
  if (!(channel != null)) {
    return show("*** You're not on a channel - try joining one. /list shows available channels.");
  } else {
    channel = sanitize(channel);
    return socket.emit('say', {
      channel: channel,
      msg: msg
    });
  }
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
  var args, command, _ref, _ref1, _ref2;
  if (isCommand(cmd)) {
    _ref = parseCommand(cmd), command = _ref.command, args = _ref.args;
  } else {
    _ref1 = {
      command: 'say',
      args: cmd
    }, command = _ref1.command, args = _ref1.args;
  }
  switch (command) {
    case 'nick':
      return newNick(args[0]);
    case 'ping':
      return ping();
    case 'join':
    case 'j':
      return join(args[0]);
    case 'names':
    case 'n':
      return names((_ref2 = args[0]) != null ? _ref2 : mychannel);
    case 'say':
    case 's':
      return say(mychannel, args);
    case 'help':
    case 'h':
      return help(args);
    default:
      return show("*** I don't know that command: " + command + ".");
  }
};

mynick = null;

mychannel = null;

$(function() {
  var focus;
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
  socket.on('disconnect', function() {
    return show("*** Disconnected from server. Please stand by as I'm trying to reconnect...");
  });
  socket.on('connect', function() {
    show("*** Connected to server.");
    return ping();
  });
  socket.on('names', function(_arg) {
    var channel, names;
    channel = _arg.channel, names = _arg.names;
    names.sort();
    show("*** There are " + names.length + " people on #" + channel + ":");
    return show("*** " + (names.join(' ')));
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
    show("*** You are now known as " + newNick + ".");
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
      $('mychannel').val(channel);
      return mychannel = channel;
    }
  });
  socket.on('say', function(_arg) {
    var channel, msg, nick;
    nick = _arg.nick, channel = _arg.channel, msg = _arg.msg;
    return show("<" + nick + " #" + channel + "> " + msg);
  });
  focus = function() {
    return $('#cmd').focus();
  };
  focus();
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

var addChannel, channels, connected, escapeHtml, execute, help, initSocket, isCommand, join, leave, mychannel, mynick, names, newNick, next, parseCommand, ping, prev, reconnect, removeChannel, sanitize, say, setChannel, show, socket,
  __slice = [].slice,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

sanitize = function(channel) {
  return channel.replace(/^#+/, '');
};

connected = false;

socket = io.connect();

channels = [];

mynick = null;

mychannel = null;

addChannel = function(channel) {
  channels.push(channel);
  return $('.ifchannel').show();
};

removeChannel = function(channel) {
  var idx;
  idx = channels.indexOf(channel);
  if (idx !== -1) {
    channels.splice(idx, 1);
  }
  if (channels.length === 0) {
    $('.ifchannel').hide();
    return null;
  } else {
    return channels[(idx - 1 + channels.length) % channels.length];
  }
};

setChannel = function(next) {
  mychannel = next;
  return $('.mychannel').html(next);
};

next = function() {
  var newChannel;
  if (channels.length <= 1 || !mychannel) {
    return;
  }
  newChannel = channels[(channels.indexOf(mychannel) + 1) % channels.length];
  return setChannel(newChannel);
};

prev = function() {
  var newChannel;
  if (channels.length <= 1 || !mychannel) {
    return;
  }
  newChannel = channels[(channels.indexOf(mychannel) - 1 + channels.length) % channels.length];
  return setChannel(newChannel);
};

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
  channel = sanitize(channel);
  return socket.emit('join', {
    channel: channel
  });
};

leave = function(channel) {
  if (!channel) {
    return show('*** Please specify channel.');
  } else {
    channel = sanitize(channel);
    return socket.emit('leave', {
      channel: channel
    });
  }
};

names = function(channel) {
  if (!channel) {
    return show('*** Please specify channel.');
  } else {
    channel = sanitize(channel);
    return socket.emit('names', {
      channel: channel
    });
  }
};

reconnect = function() {
  var uri, uuri;
  if (connected) {
    show("*** Disconnecting.");
    socket.disconnect();
  }
  uri = io.util.parseUri();
  uuri = null;
  if (window && window.location) {
    uri.protocol = uri.protocol || window.location.protocol.slice(0, -1);
    uri.host = uri.host || (window.document ? window.document.domain : window.location.hostname);
    uri.port = uri.port || window.location.port;
  }
  uuri = io.util.uniqueUri(uri);
  show("*** Reconnecting to " + uuri + ".");
  delete io.sockets[uuri];
  socket = io.connect();
  return initSocket();
};

help = function(help) {
  show("*** Available commands:");
  show("*** /nick <nick> - change nick.");
  show("*** /say <message> - say on current channel.");
  show("*** /join <channel> - join a channel. Alias: /j");
  show("*** /names [<channel>] - show who's on a channel");
  show("*** /next - next channel (shortcut: Ctrl-X)");
  show("*** /prev - previous channel");
  show("*** /leave [<channel>] - leave a channel (current channel by default)");
  show("*** /help - here we are. Alias: /h");
  show("*** /ping - ping the server.");
  return show("*** /reconnect - try to connect to the server we're not connected.");
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
  var args, command, _ref, _ref1, _ref2, _ref3;
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
    case 'reconnect':
    case 're':
    case 'reco':
      return reconnect();
    case 'leave':
    case 'le':
    case 'part':
      return leave((_ref3 = args[0]) != null ? _ref3 : mychannel);
    case 'next':
      return next();
    case 'prev':
      return prev();
    default:
      return show("*** I don't know that command: " + command + ".");
  }
};

initSocket = function() {
  socket.on('disconnect', function() {
    show("*** Disconnected from server.");
    return connected = false;
  });
  socket.on('connect', function() {
    show("*** Connected to server.");
    connected = true;
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
    var newNick, oldNick;
    oldNick = _arg.oldNick, newNick = _arg.newNick;
    if (oldNick === mynick) {
      show("*** You are now known as " + newNick + ".");
      mynick = newNick;
      return $('.mynick').html(newNick);
    } else {
      return show("*** " + oldNick + " is now known as " + newNick + ".");
    }
  });
  socket.on('error', function(data) {
    return show("*** Failed to reconnect. Please try again later.");
  });
  socket.on('info', function(_arg) {
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
    var channel, nick, tellUser;
    nick = _arg.nick, channel = _arg.channel;
    tellUser = true;
    if (nick === mynick) {
      $('.mychannel').html(channel);
      mychannel = channel;
      if (__indexOf.call(channels, channel) >= 0) {
        tellUser = false;
      } else {
        addChannel(channel);
      }
    }
    if (tellUser) {
      return show("*** " + nick + " has joined channel #" + channel + ".");
    }
  });
  socket.on('leave', function(_arg) {
    var channel, nextChannel, nick;
    nick = _arg.nick, channel = _arg.channel;
    show("*** " + nick + " has left channel #" + channel + ".");
    if (nick === mynick) {
      nextChannel = removeChannel(channel);
      if (mychannel === channel) {
        mychannel = nextChannel;
        return $('.mychannel').html(nextChannel != null ? nextChannel : '');
      }
    }
  });
  return socket.on('say', function(_arg) {
    var channel, msg, nick;
    nick = _arg.nick, channel = _arg.channel, msg = _arg.msg;
    return show("<" + nick + ":#" + channel + "> " + msg);
  });
};

$(function() {
  var clicks, focus, timer;
  mynick = $('.mynick').html();
  initSocket();
  focus = function() {
    return $('#cmd').focus();
  };
  focus();
  clicks = 0;
  timer = null;
  $(window).click(function(e) {
    console.log("### Click.");
    clicks++;
    if (clicks === 1) {
      return timer = setTimeout(function() {
        clicks = 0;
        return focus();
      }, 300);
    } else {
      clearTimeout(timer);
      return timer = setTimeout(function() {
        return clicks = 0;
      }, 300);
    }
  });
  $(window).keypress(function(e) {
    if (e.target.id !== 'cmd') {
      $('#cmd').focus();
    }
    if (e.ctrlKey && e.keyCode === 24) {
      return next();
    }
  });
  return $('#cmd').keypress(function(event) {
    var cmd;
    if (event.keyCode === 13) {
      cmd = $(event.target).val();
      execute(cmd);
      return $(event.target).val('');
    }
  });
});

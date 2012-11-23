var addChannel, channels, connected, debug, down, emit, escapeHtml, execute, formatTime, help, history, historyIdx, initSocket, isCommand, join, leave, list, log, mychannel, mynick, names, newNick, newestCommand, next, parseCommand, ping, prev, reconnect, removeChannel, s, sanitize, say, setChannel, show, socket, up, whois,
  __slice = [].slice,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

log = function() {
  return console.log.apply(console, arguments);
};

s = function() {
  return JSON.stringify.apply(JSON, arguments);
};

sanitize = function(channel) {
  return channel.replace(/^#+/, '');
};

connected = false;

socket = io.connect();

channels = [];

history = [];

historyIdx = 0;

newestCommand = '';

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
  console.log("setChannel " + next);
  mychannel = next;
  if (next) {
    $('.mychannel').html('#' + next);
    return $('.ifchannel').show();
  } else {
    $('.mychannel').html('');
    return $('.ifchannel').hide();
  }
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

debug = true;

emit = function(what, msg) {
  if (debug) {
    show("=> '" + what + "': " + (JSON.stringify(msg)));
  }
  return socket.emit(what, msg);
};

ping = function() {
  return emit('ping', {
    ts: new Date().getTime()
  });
};

newNick = function(newNick) {
  return emit('nick', {
    newNick: newNick
  });
};

join = function(channel) {
  channel = sanitize(channel);
  return emit('join', {
    channel: channel
  });
};

leave = function(channel, message) {
  if (!channel) {
    return show('*** Please specify channel.');
  } else {
    channel = sanitize(channel);
    return emit('leave', {
      channel: channel,
      message: message || "leaving"
    });
  }
};

names = function(channel) {
  if (!channel) {
    return show('*** Please specify channel.');
  } else {
    channel = sanitize(channel);
    return emit('names', {
      channel: channel
    });
  }
};

whois = function(nick) {
  if (!nick) {
    show('*** Please specify nick.');
  }
  return emit('whois', {
    nick: nick
  });
};

list = function() {
  return emit('list');
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
  show("*** /list - show channels");
  show("*** /say <message> - say on current channel.");
  show("*** /join <channel> - join a channel. Alias: /j");
  show("*** /names [<channel>] - show who's on a channel");
  show("*** /next - next channel (shortcut: Ctrl-X)");
  show("*** /prev - previous channel");
  show("*** /whois [<nick>] - show info about a person");
  show("*** /leave [<channel>] [<message>] - leave a channel (current channel by default)");
  show("*** /help - here we are. Alias: /h");
  show("*** /ping - ping the server.");
  show("*** /set - set a variables.");
  return show("*** /reconnect - try to connect to the server if we're not connected.");
};

say = function(channel, msg) {
  if (!(channel != null)) {
    return show("*** You're not on a channel - try joining one. /list shows available channels.");
  } else {
    channel = sanitize(channel);
    return emit('say', {
      channel: channel,
      msg: msg
    });
  }
};

formatTime = function(date) {
  var hours, mins;
  hours = String(date.getHours());
  mins = String(date.getMinutes());
  while (hours.length < 2) {
    hours = '0' + hours;
  }
  while (mins.length < 2) {
    mins = '0' + mins;
  }
  return "" + hours + ":" + mins;
};

show = function(msg, ts) {
  var date, time;
  if (ts == null) {
    ts = new Date().getTime();
  }
  date = new Date(ts);
  time = formatTime(date);
  $('.chat').append("<p><time datetime='" + (date.toISOString()) + "'>" + time + "</time> " + (escapeHtml(msg)) + "</p>");
  return $('.chat').scrollTop(1000000);
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

up = function() {
  var command;
  command = $('#cmd').val();
  if (historyIdx === history.length) {
    newestCommand = command;
  }
  if (--historyIdx < 0) {
    historyIdx = 0;
  }
  if (historyIdx === history.length) {
    $('#cmd').val(newestCommand);
  } else {
    $('#cmd').val(history[historyIdx]);
  }
  return $('#cmd')[0].setSelectionRange(10000, 10000);
};

down = function() {
  var command;
  command = $('#cmd').val();
  if (historyIdx === history.length) {
    newestCommand = command;
  }
  if (++historyIdx > history.length) {
    historyIdx = history.length;
  }
  if (historyIdx === history.length) {
    $('#cmd').val(newestCommand);
  } else {
    $('#cmd').val(history[historyIdx]);
  }
  return $('#cmd')[0].setSelectionRange(10000, 10000);
};

execute = function(cmd) {
  var args, command, _ref, _ref1, _ref2, _ref3, _ref4;
  if (cmd.match(/^\s*$/)) {
    return;
  }
  history.push(cmd);
  historyIdx = history.length;
  newestCommand = '';
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
    case 'whois':
    case 'w':
      return whois((_ref3 = args[0]) != null ? _ref3 : mynick);
    case 'list':
      return list();
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
      return leave((_ref4 = args[0]) != null ? _ref4 : mychannel, args.slice(1).join(' '));
    case 'next':
      return next();
    case 'prev':
      return prev();
    default:
      return show("*** I don't know that command: " + command + ".");
  }
};

initSocket = function() {
  var action, protocol, what, _results;
  protocol = {
    disconnect: function() {
      show("*** Disconnected from server.");
      return connected = false;
    },
    connect: function() {
      show("*** Connected to server.");
      connected = true;
      return ping();
    },
    names: function(_arg) {
      var channel, names;
      channel = _arg.channel, names = _arg.names;
      names.sort();
      show("*** There are " + names.length + " people on #" + channel + ":");
      return show("*** " + (names.join(' ')));
    },
    pong: function(data) {
      var backThen, now;
      backThen = data.ts;
      now = new Date().getTime();
      return show("*** pong - roundtrip " + (now - backThen) + " ms");
    },
    channels: function(data) {
      var channel, channelNames, idx, _i, _len, _ref;
      channelNames = [];
      _ref = data.channels;
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        channel = _ref[idx];
        channelNames.push('#' + channel);
      }
      if (data.you) {
        channels = data.channels;
        if (channels.length) {
          setChannel(channels[0]);
        }
        return show("*** You're on channels: " + (channelNames.join(' ')));
      } else {
        return show("*** " + data.nick + " is on channels: " + (channelNames.join(' ')));
      }
    },
    nick: function(_arg) {
      var info, newNick, oldNick, you;
      oldNick = _arg.oldNick, newNick = _arg.newNick, you = _arg.you;
      info = {
        nick: {
          oldNick: oldNick,
          newNick: newNick
        }
      };
      if (wasDuplicate(info)) {
        return;
      }
      if (you != null) {
        show("*** You are now known as " + newNick + ".");
        mynick = newNick;
        return $('.mynick').html(newNick);
      } else {
        return show("*** " + oldNick + " is now known as " + newNick + ".");
      }
    },
    error: function(data) {
      return show("*** Failed to reconnect. Please try again later.");
    },
    info: function(_arg) {
      var msg;
      msg = _arg.msg;
      return show("*** " + msg);
    },
    msg: function(_arg) {
      var from, msg;
      from = _arg.from, msg = _arg.msg;
      return show("<" + from + "> " + msg);
    },
    join: function(_arg) {
      var channel, nick, tellUser;
      nick = _arg.nick, channel = _arg.channel;
      tellUser = true;
      if (nick === mynick) {
        setChannel(channel);
        if (__indexOf.call(channels, channel) >= 0) {
          tellUser = false;
        } else {
          addChannel(channel);
        }
      }
      if (tellUser) {
        return show("*** " + nick + " has joined channel #" + channel + ".");
      }
    },
    leave: function(_arg) {
      var channel, message, nextChannel, nick;
      nick = _arg.nick, channel = _arg.channel, message = _arg.message;
      show("*** " + nick + " has left channel #" + channel + " (" + message + ").");
      if (nick === mynick) {
        nextChannel = removeChannel(channel);
        if (mychannel === channel) {
          return setChannel(nextChannel);
        }
      }
    },
    say: function(_arg) {
      var channel, msg, nick, previousInfo, wasDuplicate;
      nick = _arg.nick, channel = _arg.channel, msg = _arg.msg;
      show("<" + nick + ":#" + channel + "> " + msg);
      previousInfo = null;
      return wasDuplicate = function(info) {
        if (JSON.stringify(previousInfo) === JSON.stringify(info)) {
          return true;
        } else {
          previousInfo = info;
          return false;
        }
      };
    }
  };
  _results = [];
  for (what in protocol) {
    action = protocol[what];
    _results.push((function(what, action) {
      log("Listening to " + what + " with " + action);
      return socket.on(what, function(data) {
        log("Got command " + what);
        if (debug) {
          if (data != null) {
            show("<= '" + what + "': " + (s(data)));
          } else {
            show("<= '" + what + "'");
          }
        }
        return action(data);
      });
    })(what, action));
  }
  return _results;
};

$(function() {
  var clicks, doLayout, focus, initialChannels, timer, windowHeight;
  mynick = $('.mynick').html();
  initSocket();
  focus = function() {
    return $('#cmd').focus();
  };
  focus();
  clicks = 0;
  timer = null;
  $(window).click(function(e) {
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
      if (e.shiftKey) {
        prev();
      } else {
        next();
      }
    }
    if (e.ctrlKey && e.keyCode === 21) {
      return $('#cmd').val('');
    }
  });
  $('#cmd').keydown(function(event) {
    var cmd;
    if (event.keyCode === 13) {
      cmd = $(event.target).val();
      execute(cmd);
      $(event.target).val('');
    }
    if (event.keyCode === 38) {
      up();
      event.preventDefault();
    }
    if (event.keyCode === 40) {
      down();
      return event.preventDefault();
    }
  });
  $('#cmd').focus(function() {
    return $('.input').addClass('focus');
  });
  $('#cmd').blur(function() {
    return $('.input').removeClass('focus');
  });
  $('time').live('click', function(ev) {
    return show("*** That's " + (new Date($(ev.target).attr('datetime'))) + ".");
  });
  initialChannels = (window.location.hash.replace(/^#/, '')).trim().split(',');
  console.log("initials " + (JSON.stringify(initialChannels)));
  windowHeight = $(window).height();
  $(window).resize(function() {
    var newHeight;
    newHeight = $(window).height();
    if (newHeight !== windowHeight) {
      windowHeight = newHeight;
      return doLayout();
    }
  });
  doLayout = function() {
    var magic;
    magic = 76;
    $('.chat').css('height', windowHeight - magic);
    return $('body').css('height', windowHeight);
  };
  return doLayout();
});

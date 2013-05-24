var addChannel, allChannels, channels, connected, debug, down, emit, escapeHtml, execute, formatTime, help, history, historyIdx, initSocket, initialChannels, isCommand, join, leave, list, listen, log, mychannel, mynick, names, newNick, newestCommand, next, parseCommand, ping, prev, reconnect, removeChannel, s, sanitize, say, setChannel, show, showRaw, socket, unlisten, up, updateChannels, whois,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
  __slice = [].slice;

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

initialChannels = [];

channels = [];

allChannels = [];

history = [];

historyIdx = 0;

newestCommand = '';

mynick = null;

mychannel = null;

updateChannels = function() {
  var channel, lis, _i, _len;
  location.hash = channels.join(',');
  lis = "";
  for (_i = 0, _len = channels.length; _i < _len; _i++) {
    channel = channels[_i];
    lis += "<li>#" + channel + "</li>";
  }
  return $('.channels').html(lis);
};

addChannel = function(channel) {
  if (__indexOf.call(channels, channel) < 0) {
    channels.push(channel);
    updateChannels();
    if (channels.length > 1) {
      return $('.ifchannel').show();
    }
  }
};

removeChannel = function(channel) {
  var idx;
  idx = channels.indexOf(channel);
  if (idx !== -1) {
    channels.splice(idx, 1);
  }
  updateChannels();
  if (channels.length <= 1) {
    $('.ifchannel').hide();
  }
  if (channels.length === 0) {
    return null;
  } else {
    return channels[idx === channels.length ? idx - 1 : idx];
  }
};

setChannel = function(next) {
  mychannel = next;
  if (next) {
    addChannel(next);
    $('.mychannel').html('#' + next);
    if (channels.length >= 2) {
      $('.ifchannel').show();
    }
    return $('.channels li').each(function(idx, elem) {
      var content;
      content = $(elem).html();
      return $(elem)[content === '#' + next ? 'addClass' : 'removeClass']('current');
    });
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

debug = false;

emit = function(what, msg) {
  if (debug) {
    show("Sent " + (what.toUpperCase()) + ": " + (JSON.stringify(msg)));
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

join = function(channel, opts) {
  if (opts == null) {
    opts = {};
  }
  channel = sanitize(channel);
  opts.channel = channel;
  console.log("join; ALLCHANNELS IS: ");
  console.log(allChannels);
  return emit('join', opts);
};

listen = function(channel) {
  channel = sanitize(channel);
  return emit('listen', {
    channel: channel
  });
};

unlisten = function(channel) {
  channel = sanitize(channel);
  return emit('unlisten', {
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
  show("*** /listen <channel> - listen to a channel.");
  show("*** /unlisten <channel> - don't listen to a channel.");
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
  return showRaw(escapeHtml(msg), ts);
};

showRaw = function(msg, ts) {
  var date, time;
  if (ts == null) {
    ts = new Date().getTime();
  }
  date = new Date(ts);
  time = formatTime(date);
  $('.chat').append("<p><time datetime='" + (date.toISOString()) + "'>" + time + "</time> " + msg + "</p>");
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
    case 'listen':
      return listen(args[0]);
    case 'unlisten':
      return unlisten(args[0]);
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
    case 'raw':
      return emit(args[0], JSON.parse(args.slice(1).join(' ')));
    default:
      return show("*** I don't know that command: " + command + ".");
  }
};

initSocket = function() {
  var action, previousInfo, protocol, wasDuplicate, what, _results;
  previousInfo = null;
  wasDuplicate = function(info) {
    if (JSON.stringify(previousInfo) === JSON.stringify(info)) {
      return true;
    } else {
      previousInfo = info;
      return false;
    }
  };
  protocol = {
    disconnect: function() {
      show("*** Disconnected from server.");
      return connected = false;
    },
    connect: function() {
      show("*** Connected to server.");
      connected = true;
      if (debug) {
        return ping();
      }
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
      var channel, channelNames, idx, _i, _j, _len, _len1, _ref, _ref1;
      channelNames = [];
      _ref = data.channels;
      for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
        channel = _ref[idx];
        channelNames.push('#' + channel);
      }
      if (data.you) {
        allChannels = data.channels;
        if (!initialChannels.length) {
          _ref1 = data.channels;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            channel = _ref1[_j];
            listen(channel);
          }
        }
        if (data.channels.length) {
          return show("*** You're on channels: " + (channelNames.join(' ')));
        } else {
          return show("*** You're not on any channels.");
        }
      } else {
        return show("*** " + data.nick + " is on channels: " + (channelNames.join(' ')));
      }
    },
    listen: function(_arg) {
      var channel, nick, you;
      nick = _arg.nick, channel = _arg.channel, you = _arg.you;
      if (!you) {
        show("*** TODO FIXME BROKEN IS THIS");
      }
      return setChannel(channel);
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
      if (you) {
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
      return show("[info] " + msg);
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
      var channel, msg, nick, style;
      nick = _arg.nick, channel = _arg.channel, msg = _arg.msg;
      style = channels.length <= 1 ? 'display: none' : '';
      return showRaw("&lt;" + (escapeHtml(nick)) + "<span class='ifchannel' style='" + style + "'>:#" + (escapeHtml(channel)) + "</span>&gt; " + (escapeHtml(msg)));
    }
  };
  _results = [];
  for (what in protocol) {
    action = protocol[what];
    _results.push((function(what, action) {
      return socket.on(what, function(data) {
        if (debug) {
          if (data != null) {
            show("Got " + (what.toUpperCase()) + ": " + (s(data)));
          } else {
            show("Got " + (what.toUpperCase()));
          }
        }
        return action(data);
      });
    })(what, action));
  }
  return _results;
};

$(function() {
  var c, channelsInHash, clicks, doLayout, focus, timer, windowHeight, _i, _j, _len, _len1;
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
  $('.channels li').live('click', function(ev) {
    var channel;
    channel = $(ev.target).html();
    return setChannel(sanitize(channel));
  });
  $('time').live('click', function(ev) {
    return show("*** That's " + (new Date($(ev.target).attr('datetime'))) + ".");
  });
  channelsInHash = (window.location.hash.replace(/^#/, '')).trim().split(',');
  for (_i = 0, _len = channelsInHash.length; _i < _len; _i++) {
    c = channelsInHash[_i];
    if (c) {
      initialChannels.push(c);
    }
  }
  console.log("initials " + (JSON.stringify(initialChannels)));
  for (_j = 0, _len1 = initialChannels.length; _j < _len1; _j++) {
    c = initialChannels[_j];
    join(c, {
      silent: true
    });
  }
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

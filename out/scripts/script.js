(function() {
  var $, App, Backbone, MD5, app, jQuery, showNotification, socket, webkitNotifications, _;

  webkitNotifications = window.webkitNotifications;

  jQuery = window.jQuery;

  $ = window.$;

  Backbone = window.Backbone;

  _ = window._;

  MD5 = window.MD5;

  App = {
    views: {},
    models: {},
    collections: {}
  };

  if (webkitNotifications.checkPermission()) {
    $(document.body).click(function() {
      webkitNotifications.requestPermission();
      return $(document.body).unbind();
    });
  }

  showNotification = function(_arg) {
    var avatar, content, notification, timer, title;
    title = _arg.title, content = _arg.content, avatar = _arg.avatar;
    if (!webkitNotifications.checkPermission()) {
      avatar || (avatar = "");
      title || (title = "New message");
      content || (content = "");
      timer = null;
      notification = webkitNotifications.createNotification(avatar, title, content);
      notification.ondisplay = function() {
        return timer = setTimeout(function() {
          return notification.cancel();
        }, 5000);
      };
      notification.onclose = function() {
        if (timer) {
          clearTimeout(timer);
          return timer = null;
        }
      };
      return notification.show();
    }
  };

  App.models.Base = Backbone.Model.extend({});

  App.models.App = App.models.Base.extend({
    defaults: {
      user: null,
      users: null,
      messages: null
    }
  });

  App.models.User = App.models.Base.extend({
    url: 'user',
    defaults: {
      email: null,
      displayname: null,
      avatar: null
    },
    initialize: function() {
      var cid, displayname;
      var _this = this;
      cid = this.cid;
      displayname = this.get('displayname');
      if (!displayname) {
        displayname = 'unknown';
        this.set({
          displayname: displayname
        });
      }
      this.bind('change:id', function(model, id) {
        displayname = _this.get('displayname');
        if (displayname === 'unknown' || !displayname) {
          return _this.set({
            displayname: "User " + id
          });
        }
      });
      this.bind('change:email', function(model, email) {
        var avatarHash, avatarSize, avatarUrl;
        if (email) {
          avatarSize = 80;
          avatarHash = MD5(email);
          avatarUrl = "http://www.gravatar.com/avatar/" + avatarSize + ".jpg?s=" + avatarSize;
        } else {
          avatarUrl = null;
        }
        return _this.set({
          avatar: avatarUrl
        });
      });
      return this;
    }
  });

  App.models.Message = App.models.Base.extend({
    url: 'message',
    defaults: {
      posted: null,
      content: null,
      author: null
    },
    initialize: function() {
      var posted;
      posted = this.get('posted');
      this.bind('change:author', function(model, author) {
        if (author) {
          if (!(author instanceof App.models.User)) {
            return this.set({
              author: new App.models.User(author)
            });
          }
        }
      });
      this.bind('change:posted', function(model, posted) {
        if (posted) {
          if (!(posted instanceof Date)) {
            return this.set({
              posted: new Date(posted)
            });
          }
        }
      });
      this.set({
        posted: !posted ? new Date() : void 0
      });
      return this;
    }
  });

  App.collections.Base = Backbone.Collection.extend({});

  App.collections.Users = App.collections.Base.extend({
    model: App.models.User
  });

  App.collections.Messages = App.collections.Base.extend({
    model: App.models.Message
  });

  App.views.Base = Backbone.View.extend({
    _initialize: function() {
      this.views = {};
      if (this.el && this.options.container) {
        this.el.appendTo(this.options.container);
      }
      return this;
    },
    initialize: function() {
      return this._initialize();
    }
  });

  App.views.UserForm = App.views.Base.extend({
    initialize: function() {
      var _this = this;
      this.el = $('#views > .userForm.view').clone().data('view', this);
      this.model.bind('change', function() {
        return _this.populate();
      });
      return this._initialize();
    },
    populate: function() {
      var $displayname, $email, $id, displayname, email, id;
      id = this.model.get('id');
      displayname = this.model.get('displayname');
      email = this.model.get('email');
      $id = this.$('.id').val(id);
      $displayname = this.$('.displayname').val(displayname);
      return $email = this.$('.email').val(email);
    },
    render: function() {
      var $cancelButton, $closeButton, $displayname, $email, $id, $submitButton;
      var _this = this;
      this.populate();
      $id = this.$('.id');
      $displayname = this.$('.displayname');
      $email = this.$('.email');
      $submitButton = this.$('.submitButton');
      $cancelButton = this.$('.cancelButton');
      $closeButton = this.$('.close');
      $displayname.add($email).keypress(function(event) {
        if (event.keyCode === 13) {
          event.preventDefault();
          return $submitButton.trigger('click');
        }
      });
      $submitButton.click(function() {
        _this.model.set({
          displayname: $displayname.val(),
          email: $email.val()
        });
        _this.hide();
        return _this.trigger('update', _this.model);
      });
      $cancelButton.add($closeButton).click(function() {
        _this.hide();
        return _this.populate();
      });
      return this;
    },
    hide: function() {
      this.el.hide();
      return this;
    },
    show: function() {
      var $displayname;
      this.el.show();
      $displayname = this.$('.displayname');
      $displayname.focus();
      return this;
    }
  });

  App.views.Users = App.views.Base.extend({
    initialize: function() {
      var _this = this;
      this.el = $('#views > .users.view').clone().data('view', this);
      this.model.bind('add', function(user) {
        return _this.addUser(user);
      });
      this.model.bind('remove', function(user) {
        return _this.removeUser(user);
      });
      return this._initialize();
    },
    addUser: function(user) {
      var $userList, userId, userKey;
      $userList = this.$('.userList');
      userId = user.get('id');
      userKey = "user-" + userId;
      this.views[userKey] = new App.views.User({
        model: user,
        container: $('<tr><td class="user wrapper"></tr>').appendTo($userList).find('.user.wrapper')
      }).render();
      return this;
    },
    removeUser: function(user) {
      var $userList, userId, userKey;
      $userList = this.$('.userList');
      userId = user.get('id');
      userKey = "user-" + userId;
      this.views[userKey].remove();
      return this;
    },
    populate: function() {
      var $userList, users;
      var _this = this;
      this.views = {};
      users = this.model;
      $userList = this.$('.userList').empty();
      users.each(function(user) {
        return _this.addUser(user);
      });
      return this;
    },
    render: function() {
      this.populate();
      return this;
    }
  });

  App.views.User = App.views.Base.extend({
    initialize: function() {
      var _this = this;
      this.el = $('#views > .user.view').clone().data('view', this);
      this.model.bind('change', function() {
        return _this.populate();
      });
      return this._initialize();
    },
    populate: function() {
      var $avatar, $displayname, $email, $id, avatar, displayname, email, id;
      id = this.model.get('id');
      displayname = this.model.get('displayname');
      email = this.model.get('email');
      avatar = this.model.get('avatar');
      $id = this.$('.id');
      $email = this.$('.email');
      $displayname = this.$('.displayname');
      $avatar = this.$('.avatar');
      $id.text(id || '');
      $displayname.text(displayname || '');
      $email.text(email || '');
      $avatar.empty();
      if (avatar) $('<img class="avatarImage">').appendTo($avatar).attr('src');
      return this;
    },
    render: function() {
      this.populate();
      return this;
    }
  });

  App.views.Messages = App.views.Base.extend({
    initialize: function() {
      var _this = this;
      this.el = $('#views > .messages.view').clone().data('view', this);
      this.model.bind('add', function(message) {
        return _this.addMessage(message);
      });
      return this._initialize();
    },
    addMessage: function(message) {
      var $messageList, messageId, messageKey;
      $messageList = this.$('.messageList');
      messageId = message.get('id');
      messageKey = "message-" + messageId;
      this.views[messageKey] = new App.views.Message({
        model: message,
        container: $messageList
      }).render();
      return this;
    },
    populate: function() {
      var $messageList, messages;
      var _this = this;
      this.views = {};
      messages = this.model;
      $messageList = this.$('.messageList').empty();
      messages.each(function(message) {
        return _this.addMessage(message);
      });
      return this;
    },
    render: function() {
      this.populate();
      return this;
    }
  });

  App.views.Message = App.views.Base.extend({
    initialize: function() {
      this.el = $('#views .message.view').clone().data('view', this);
      return this._initialize();
    },
    populate: function() {
      var $author, $content, $id, $posted, $time, author, content, id, posted;
      $id = this.$('.id');
      $content = this.$('.content');
      $posted = this.$('.posted');
      $author = this.$('.author.wrapper');
      id = this.model.get('id');
      posted = this.model.get('posted');
      author = this.model.get('author');
      content = this.model.get('content');
      $id.text(id);
      $content.text(content);
      $time = $("<time>").attr('datetime', posted.toUTCString()).appendTo($posted.empty()).timeago(posted);
      this.views.author = new App.views.User({
        model: author,
        container: $author
      }).render();
      return this;
    },
    render: function() {
      this.populate();
      return this;
    }
  });

  App.views.Notification = App.views.Base.extend({
    initialize: function() {
      this.el = $('#views > .notification.view').clone().data('view', this);
      return this._initialize();
    },
    populate: function() {
      var $content, $title, content, title;
      title = this.options.title;
      content = this.options.content;
      $title = this.$('.title');
      $content = this.$('.content');
      $title.text(title || '').toggle(!!title);
      $content.text(content || '').toggle(!!content);
      return this;
    },
    render: function() {
      var _this = this;
      this.populate();
      if (this._timeout) {
        clearTimeout(this._timeout);
        this._timeout = null;
      }
      this.el.stop(true, true).hide().fadeIn(200, function() {
        return _this._timeout = setTimeout(function() {
          return _this.el.fadeOut(200, function() {
            if (!((_this.options.destroy != null) && _this.options.destroy === false)) {
              return _this.remove();
            }
          });
        }, 2000);
      });
      return this;
    }
  });

  App.views.App = App.views.Base.extend({
    initialize: function() {
      this.el = $('#views > .app.view').clone().data('view', this);
      return this._initialize();
    },
    resize: function() {
      var $header, $messageForm, $messagesView, $messagesWrapper, $usersWrapper, $window;
      var _this = this;
      $window = $(window);
      $header = this.$('.header.topbar');
      $messagesWrapper = this.$('.messages.wrapper');
      $messagesView = $messagesWrapper.find('.messages.view');
      $usersWrapper = this.$('.users.wrapper');
      $messageForm = this.$('.messageForm');
      $usersWrapper.height($window.height());
      $messagesWrapper.width($window.width() - $usersWrapper.outerWidth());
      $messageForm.width($window.width() - $usersWrapper.outerWidth());
      $messagesWrapper.height($window.height() - $messageForm.outerHeight() - $header.outerHeight());
      return setTimeout(function() {
        return $messagesWrapper.prop('scrollTop', $messagesView.outerHeight());
      }, 100);
    },
    start: function($container) {
      var me, messages, socket, system, user, users;
      var _this = this;
      me = this;
      socket = this.options.socket;
      system = new App.models.User({
        displayname: 'system',
        email: 'nodechat@bevry.me'
      });
      user = new App.models.User();
      users = new App.collections.Users();
      messages = new App.collections.Messages();
      this.model.set({
        user: user,
        users: users,
        messages: messages
      });
      messages.bind('add', function(message) {
        var messageAuthor;
        _this.resize();
        messageAuthor = message.get('author');
        if (messageAuthor.get('id') === user.get('id')) return;
        return showNotification({
          title: messageAuthor.get('displayname') + ' says:',
          avatar: messageAuthor.get('avatar'),
          content: message.get('content')
        });
      });
      socket.on('connect', function() {
        return socket.emit('handshake1', function(err, userId) {
          if (err) throw err;
          user.set({
            id: userId
          });
          return socket.emit('handshake2', user, function(err, _users) {
            var displayname;
            var _this = this;
            if (err) throw err;
            displayname = user.get('displayname');
            user.save();
            users.add(user);
            messages.add(new App.models.Message({
              author: system,
              content: "Welcome " + displayname
            }));
            _.each(_users, function(_user) {
              return me.user('add', _user);
            });
            return $(function() {
              return me.render();
            });
          });
        });
      });
      socket.on('user', function(method, data) {
        return _this.user(method, data);
      });
      socket.on('message', function(method, data) {
        return _this.message(method, data);
      });
      return this;
    },
    user: function(method, data) {
      var user, users;
      users = this.model.get('users');
      switch (method) {
        case 'delete':
        case 'remove':
          users.remove(data.id);
          break;
        case 'create':
        case 'update':
        case 'add':
          user = users.get(data.id);
          if (user) {
            user.set(data);
          } else {
            user = new App.models.User();
            user.set(data);
            users.add(user);
          }
      }
      return this;
    },
    message: function(method, data) {
      var message, messages;
      messages = this.model.get('messages');
      switch (method) {
        case 'delete':
        case 'remove':
          messages.remove(data.id);
          break;
        case 'create':
        case 'update':
        case 'add':
          message = messages.get(data.id);
          if (message) {
            message.set(data);
          } else {
            message = new App.models.Message();
            message.set(data);
            messages.add(message);
          }
      }
      return this;
    },
    render: function() {
      var $editUserButton, $messageInput, $messages, $notificationList, $userForm, $users, messages, user, users;
      var _this = this;
      user = this.model.get('user');
      users = this.model.get('users');
      messages = this.model.get('messages');
      $editUserButton = this.$('.editUserButton');
      $messages = this.$('.messages.wrapper');
      $userForm = this.$('.userForm.wrapper');
      $users = this.$('.users.wrapper');
      $messageInput = this.$('.messageInput');
      $notificationList = this.$('.notificationList');
      this.views = {};
      this.views.messages = new App.views.Messages({
        model: messages,
        container: $messages
      }).render();
      this.views.users = new App.views.Users({
        model: users,
        container: $users
      }).render();
      this.views.userForm = new App.views.UserForm({
        model: user,
        container: $userForm
      }).render().hide().bind('update', function(user) {
        var notification;
        user.save();
        return notification = new App.views.Notification({
          title: 'Changes saved successfully',
          container: $notificationList
        }).render();
      });
      $editUserButton.click(function() {
        return _this.views.userForm.show();
      });
      $messageInput.bind('keypress', function(event) {
        var messageContent;
        if (event.keyCode === 13) {
          event.preventDefault();
          messageContent = $messageInput.val();
          $messageInput.val('');
          return messages.create({
            author: user,
            content: messageContent
          });
        }
      });
      $messageInput.focus();
      this.resize();
      return this;
    }
  });

  $.timeago.settings.strings.seconds = "moments";

  socket = io.connect('http://localhost:10113/');

  Backbone.sync = function(method, model, options) {
    var data;
    data = model.toJSON();
    return socket.emit(model.url, method, data, function(err, data) {
      if (err) throw err;
      return typeof options.success === "function" ? options.success(data) : void 0;
    });
  };

  app = new App.views.App({
    socket: socket,
    container: $('#app'),
    model: new App.models.App()
  });

  app.start();

  window.app = app;

  window.App = App;

}).call(this);

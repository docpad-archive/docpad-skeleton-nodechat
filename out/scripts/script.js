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
      var cid, username;
      var _this = this;
      cid = this.cid;
      username = this.get('username');
      if (!username) {
        username = 'unknown';
        this.set({
          username: username
        });
      }
      this.bind('change:id', function(model, id) {
        username = _this.get('username');
        if (username === 'unknown' || !username) {
          return _this.set({
            username: "User " + id
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
      var $email, $fullname, $id, $username, email, fullname, id, username;
      id = this.model.get('id');
      username = this.model.get('username');
      email = this.model.get('email');
      fullname = this.model.get('fullname');
      $id = this.$('.id').val(id);
      $username = this.$('.username').val(username);
      $email = this.$('.email').val(email);
      return $fullname = this.$('.fullname').val(fullname);
    },
    render: function() {
      var $cancelButton, $closeButton, $email, $fullname, $id, $submitButton, $username;
      var _this = this;
      this.populate();
      $id = this.$('.id');
      $username = this.$('.username');
      $email = this.$('.email');
      $fullname = this.$('.fullname');
      $submitButton = this.$('.submitButton');
      $cancelButton = this.$('.cancelButton');
      $closeButton = this.$('.close');
      $submitButton.click(function() {
        _this.model.set({
          username: $username.val(),
          email: $email.val(),
          fullname: $fullname.val()
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
      this.el.show();
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
        container: $userList
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
      var $userLIst, users;
      var _this = this;
      this.views = {};
      users = this.model;
      $userLIst = this.$('.userLIst').empty();
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
      var $avatar, $email, $fullname, $id, $username, avatar, email, fullname, id, username;
      id = this.model.get('id');
      username = this.model.get('username');
      email = this.model.get('email');
      fullname = this.model.get('fullname');
      avatar = this.model.get('avatar');
      $id = this.$('.id');
      $username = this.$('.username');
      $email = this.$('.email');
      $fullname = this.$('.fullname');
      $avatar = this.$('.avatar');
      $id.text(id || '').toggle(!!id);
      $username.text(username || '').toggle(!!username);
      $email.text(email || '').toggle(!!email);
      $fullname.text(fullname || '').toggle(!!fullname);
      $avatar.attr('src', avatar || '').toggle(!!avatar);
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

  App.views.App = App.views.Base.extend({
    initialize: function() {
      this.el = $('#views > .app.view').clone().data('view', this);
      return this._initialize();
    },
    start: function($container) {
      var me, messages, socket, system, user, users;
      var _this = this;
      me = this;
      socket = this.options.socket;
      system = new App.models.User({
        username: 'system',
        email: 'b@lupton.cc'
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
        messageAuthor = message.get('author');
        if (messageAuthor.get('id') === user.get('id')) return;
        return showNotification({
          title: messageAuthor.get('username') + ' says:',
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
            var username;
            var _this = this;
            if (err) throw err;
            username = user.get('username');
            user.save();
            users.add(user);
            messages.add(new App.models.Message({
              author: system,
              content: "Welcome " + username
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
      var $editUserButton, $messageInput, $messages, $userForm, $users, messages, user, users;
      var _this = this;
      user = this.model.get('user');
      users = this.model.get('users');
      messages = this.model.get('messages');
      $editUserButton = this.$('.editUserButton');
      $messages = this.$('.messages.wrapper');
      $userForm = this.$('.userForm.wrapper');
      $users = this.$('.users.wrapper');
      $messageInput = this.$('.messageInput');
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
      }).render().hide();
      $editUserButton.click(function() {
        return _this.views.userForm.show().bind('update', function(user) {
          return user.save();
        });
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

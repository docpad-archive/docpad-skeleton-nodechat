(function() {
  var $, App, Backbone, app, jQuery, showNotification, socket, webkitNotifications, _;

  webkitNotifications = window.webkitNotifications;

  jQuery = window.jQuery;

  $ = window.$;

  Backbone = window.Backbone;

  _ = window._;

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

  App.models.Base = Backbone.Model.extend({
    _initialize: function() {
      var id;
      id = this.get('id');
      if (!id) {
        return this.set({
          id: Math.random()
        });
      }
    },
    initialize: function() {
      return this._initialize();
    }
  });

  App.models.App = App.models.Base.extend({
    defaults: {
      user: null,
      users: null,
      messages: null
    }
  });

  App.models.User = App.models.Base.extend({
    defaults: {
      username: null,
      email: null,
      fullname: null,
      avatar: null
    },
    url: '/user',
    initialize: function() {
      var avatarHash, avatarSize, avatarUrl, email, id, username;
      this._initialize();
      id = this.get('id');
      email = this.get('email');
      username = this.get('username');
      if (!username) {
        username = "User " + id;
        this.set({
          username: username
        });
      }
      if (email) {
        avatarSize = 80;
        avatarHash = window.MD5(email);
        avatarUrl = "http://www.gravatar.com/avatar/" + avatarSize + ".jpg?s=" + avatarSize;
      } else {
        avatarUrl = null;
      }
      this.set({
        avatar: avatarUrl
      });
      return this;
    }
  });

  App.models.Message = App.models.Base.extend({
    defaults: {
      posted: null,
      content: null,
      author: null
    },
    url: '/message',
    initialize: function() {
      var posted;
      this._initialize();
      posted = this.get('posted');
      if (posted) {
        this.set({
          posted: new Date(posted)
        });
      } else {
        this.set({
          posted: new Date()
        });
      }
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
        return _this.hide();
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
      var messages, socket, system, user, users;
      var _this = this;
      system = new App.models.User({
        username: 'system',
        email: 'b@lupton.cc'
      });
      socket = this.options.socket;
      user = new App.models.User();
      users = new App.collections.Users();
      messages = new App.collections.Messages(new App.models.Message({
        author: system,
        content: 'Welcome!'
      }));
      this.model.set({
        system: system,
        user: user,
        users: users,
        messages: messages
      });
      $(function() {
        return _this.render();
      });
      return this;
    },
    addUser: function(data) {
      var user, users;
      console.log('user:', data);
      users = this.model.get('users');
      user = data.id ? users.get(data.id) : null;
      if (user) {
        user = user.set(data);
      } else {
        user = new App.models.User(data);
        users.add(user);
        Backbone.sync('create', user);
      }
      return user;
    },
    addMessage: function(data) {
      var message, messages;
      console.log('message:', data);
      messages = this.model.get('messages');
      message = data.id ? messages.get(data.id) : null;
      if (message) {
        message = message.set(data);
      } else {
        data.author = this.addUser(data.author);
        message = new App.models.Message(data);
        messages.add(message);
        Backbone.sync('create', message);
        if (message.get('author').get('id') !== this.model.get('user').get('id')) {
          showNotification({
            title: message.get('author').get('username') + ' says:',
            avatar: message.get('author').get('avatar'),
            content: message.get('content')
          });
        }
      }
      return message;
    },
    render: function() {
      var $editUserButton, $messageInput, $messages, $userForm, messages, user;
      var _this = this;
      user = this.model.get('user');
      messages = this.model.get('messages');
      $editUserButton = this.$('.editUserButton');
      $messages = this.$('.messages.wrapper');
      $userForm = this.$('.userForm.wrapper');
      $messageInput = this.$('.messageInput');
      this.views = {};
      this.views.messages = new App.views.Messages({
        model: messages,
        container: $messages
      }).render();
      this.views.userForm = new App.views.UserForm({
        model: user,
        container: $userForm
      }).render().hide();
      $editUserButton.click(function() {
        return _this.views.userForm.show();
      });
      $messageInput.bind('keypress', function(event) {
        var message;
        if (event.keyCode === 13) {
          event.preventDefault();
          message = $messageInput.val();
          _this.addMessage({
            author: user.toJSON(),
            content: message
          });
          return $messageInput.val('');
        }
      });
      return this;
    }
  });

  $.timeago.settings.strings.seconds = "moments";

  socket = io.connect('http://localhost:10113/');

  app = new App.views.App({
    socket: socket,
    container: $('#app'),
    model: new App.models.App()
  });

  app.start();

  socket.on('connect', function() {
    var _this = this;
    console.log('connected');
    socket.on("user", function(data) {
      console.log('received user');
      return app.addUser(data);
    });
    return socket.on("message", function(data) {
      console.log('received message');
      return app.addMessage(data);
    });
  });

  window.app = app;

  window.App = App;

}).call(this);

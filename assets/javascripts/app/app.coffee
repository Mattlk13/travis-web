require 'travis' # hrm.
require 'controllers'
require 'helpers'
require 'models'
require 'pusher'
require 'routes'
require 'store'
require 'tailing'
require 'templates'
require 'views'

require 'config/locales'
require 'data/sponsors'
require 'travis/auth'

# $.mockjaxSettings.log = false
# Ember.LOG_BINDINGS = true
# Ember.ENV.RAISE_ON_DEPRECATION = true
# Pusher.log = -> console.log(arguments)

Travis.reopen
  App: Em.Application.extend
    init: ->
      @_super()
      @connect()

      @store = Travis.Store.create()
      @store.loadMany(Travis.Sponsor, Travis.SPONSORS)

      @routes = new Travis.Routes()
      @pusher = new Travis.Pusher()
      @tailing = new Travis.Tailing()

      @loadUser()

    loadUser: ->
      user = sessionStorage?.getItem("travisUser")
      if user
        @setCurrentUser JSON.parse(user)
      else if localStorage?.getItem("travisTrySignIn")
        Travis.Auth.trySignIn()

    signIn: ->
      Travis.Auth.signIn()
      # TODO: this has to mov, no?
      @render.apply(this, @get('returnTo') || ['home', 'index'])

    signOut: ->
      Travis.config.access_token = null
      localStorage?.clear()
      sessionStorage?.clear()
      @setCurrentUser()

    setCurrentUser: (data) ->
      data = JSON.parse(data) if typeof data == 'string'
      if data
        localStorage?.setItem("travisTrySignIn", "true")
        sessionStorage?.setItem("travisUser", JSON.stringify(data))
        @store.load(Travis.User, data.user)
        @store.loadMany(Travis.Account, data.accounts)
      @set('currentUser', if data then Travis.User.find(data.user.id) else undefined)

    render: (name, action, params) ->
      layout = @connectLayout(name)
      layout.activate(action, params || {})
      $('body').attr('id', name)

    receive: ->
      @store.receive.apply(@store, arguments)

    connectLayout: (name) ->
      unless @get('layout.name') == name
        name = $.camelize(name)
        viewClass = Travis["#{name}Layout"]
        @layout = Travis["#{name}Controller"].create(parent: @controller)
        @controller.connectOutlet(outletName: 'layout', controller: @layout, viewClass: viewClass)
      @layout

    connect: ->
      @controller = Em.Controller.create()
      view = Em.View.create
        template: Em.Handlebars.compile('{{outlet layout}}')
        controller: @controller
      view.appendTo(@get('rootElement') || 'body')

    toggleSidebar: ->
      $('body').toggleClass('maximized')
      # TODO gotta force redraws here :/
      element = $('<span></span>')
      $('#top .profile').append(element)
      Em.run.later (-> element.remove()), 10
      element = $('<span></span>')
      $('#repository').append(element)
      Em.run.later (-> element.remove()), 10


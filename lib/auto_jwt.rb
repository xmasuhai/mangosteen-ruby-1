class AutoJwt
  def initialize(app)
    @app = app
  end

  def call(env)
    [ 200, {}, [ "Hello World!", "Hi!" ] ]
  end
end

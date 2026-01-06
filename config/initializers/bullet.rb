if Rails.env.development?
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true
      Bullet.alert = true        # browser alerts
      Bullet.bullet_logger = true
      Bullet.console = true      # log in browser console
      Bullet.rails_logger = true # log to Rails log
      Bullet.add_footer = true   # adds info in page footer
    end
  end
end

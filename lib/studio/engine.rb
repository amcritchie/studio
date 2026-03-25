module Studio
  class Engine < ::Rails::Engine
    initializer "studio.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
    end

    initializer "studio.assets" do |app|
      app.config.assets.paths << root.join("app/assets/javascripts")
    end
  end
end

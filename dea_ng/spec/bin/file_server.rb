#!/usr/bin/env ruby

require "fileutils"
require "thin"
require "sinatra/base"
require "pp"

APPS_DIR = File.expand_path("../../fixtures/apps", __FILE__)
BUILDPACK_CACHE_DIR = File.expand_path("../../fixtures/buildpack_cache", __FILE__)
BUILDPACKS_DIR = File.expand_path("../../fixtures/fake_buildpacks", __FILE__)
STAGED_APPS_DIR = "/tmp/dea"
FileUtils.mkdir_p(STAGED_APPS_DIR)

class FileServer < Sinatra::Base
  get "/unstaged/:name" do |name|
    zip_path = "/tmp/fixture-#{name}.zip"

    app_path = if name == "node_buildpack_tests"
      File.expand_path("../../../buildpacks/vendor/nodejs", __FILE__)
    else
      "#{APPS_DIR}/#{name}"
    end

    Dir.chdir(app_path) do
      system "rm -rf #{zip_path} && zip -r #{zip_path} ."
    end
    send_file(zip_path)
  end

  post "/staged/:name" do |name|
    droplet = params["upload"]["droplet"]
    FileUtils.mv(droplet[:tempfile].path, file_path(name))
    200
  end

  get "/staged/:name" do |name|
    send_file(file_path(name))
  end

  get "/buildpack_cache" do
    tarball = "/tmp/buildpack_cache.tgz"
    Dir.chdir(BUILDPACK_CACHE_DIR) do
      system "rm -rf #{tarball} && tar -czf #{tarball} ."
    end
    send_file(tarball)
  end

  post "/buildpack_cache" do
    droplet = params["upload"]["droplet"]
    FileUtils.mv(droplet[:tempfile].path, file_path("buildpack_cache.tgz"))
    200
  end

  private

  def file_path(name)
    "#{STAGED_APPS_DIR}/#{name}"
  end
end

app = Rack::Builder.new do
  map "/buildpacks" do
    run Rack::Directory.new(BUILDPACKS_DIR)
  end

  run FileServer.new
end

$stdout.sync = true
Rack::Handler::Thin.run(app, :Port => 9999)

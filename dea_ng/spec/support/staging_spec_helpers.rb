require 'tmpdir'

module StagingSpecHelpers
  def app_fixture(name)
    @app_fixture = name.to_s
  end

  def stage(config = {})
    raise "Call 'app_fixture :name_of_app' before staging" unless @app_fixture
    working_dir = Dir.mktmpdir("#{@app_fixture}-staged")

    stringified_config = {}
    config.each_pair { |k, v| stringified_config[k.to_s] = v }

    config = {
      "source_dir" => app_source,
      "dest_dir" => working_dir,
      "environment" => []
    }.merge(stringified_config)

    config["staging_info_path"] = staging_info_path

    Buildpacks::Buildpack.new(config).stage_application
    Dir.chdir(working_dir) do
      yield Pathname.new(working_dir) if block_given?
    end
  ensure
    FileUtils.rm_r(working_dir) if working_dir
    FileUtils.rm_f(staging_info_path)
  end

  def staging_info_path
    @staging_info_path ||= Tempfile.new("staging_info").path
  end

  private

  def app_fixture_base_directory
    Pathname.new(File.expand_path('../../fixtures/apps', __FILE__))
  end

  def app_source
    app_fixture_base_directory.join(@app_fixture).to_s
  end
end
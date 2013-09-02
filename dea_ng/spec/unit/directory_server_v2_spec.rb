require "spec_helper"
require "dea/directory_server_v2"
require "dea/instance_registry"
require "dea/staging_task_registry"

describe Dea::DirectoryServerV2 do
  let(:instance_registry) do
    instance_registry = nil
    em do
      instance_registry = Dea::InstanceRegistry.new({})
      done
    end
    instance_registry
  end
  let(:staging_task_registry) { Dea::StagingTaskRegistry.new }

  let(:config) { {"directory_server" => {"file_api_port" => 3456}} }
  subject { Dea::DirectoryServerV2.new("domain", 1234, config) }

  describe "#initialize" do
    it "sets up hmac helper with correct key" do
      subject.hmac_helper.key.should be_a(String)
    end
  end

  describe "#configure_endpoints" do
    before { subject.configure_endpoints(instance_registry, staging_task_registry) }

    it "sets up file api server" do
      subject.file_api_server.tap do |s|
        s.should be_an_instance_of Thin::Server
        s.host.should == "127.0.0.1"
        s.port.should == 3456
        s.app.should_not be_nil
      end
    end

    it "configures instance paths resource endpoints" do
      Dea::DirectoryServerV2::InstancePaths.settings.tap do |s|
        s[:directory_server].should == subject
        s[:instance_registry].should == instance_registry
        s[:max_url_age_secs].should == 3600
      end
    end

    it "configures staging tasks resource endpoints" do
      Dea::DirectoryServerV2::StagingTasks.settings.tap do |s|
        s[:directory_server].should == subject
        s[:staging_task_registry].should == staging_task_registry
        s[:max_url_age_secs].should == 3600
      end
    end
  end

  describe "#start" do
    context "when file api server was configured" do
      before { subject.configure_endpoints(instance_registry, staging_task_registry) }

      # For debugging you can do 'Thin::Logging.silent = false'
      def make_request(url)
        response = nil
        em(:timeout => 1) do
          subject.start

          http = EM::HttpRequest.new(url).get
          on_response = lambda do |*args|
            response = http.response
            done
          end

          http.errback(&on_response)
          http.callback(&on_response)
        end
        response
      end

      def localize_url(url)
        url.sub(subject.external_hostname, "localhost:3456")
      end

      it "can handle instance paths requests" do
        url = subject.instance_file_url_for("instance-id", "some-file-path")
        response = make_request(localize_url(url))
        response.should include("Unknown instance")
      end

      it "can handle staging tasks requests" do
        url = subject.staging_task_file_url_for("task-id", "some-file-path")
        response = make_request(localize_url(url))
        response.should include("Unknown staging task")
      end
    end

    context "when file api server was not configured" do
      it "starts the file api server" do
        expect {
          subject.start
        }.to raise_error(ArgumentError, /file api server must be configured/)
      end
    end
  end

  describe "url generation" do
    def self.it_generates_url(path)
      it "includes external host" do
        url.should start_with("http://#{subject.uuid}.domain")
      end

      it "includes path" do
        url.should include(".domain#{path}")
      end
    end

    def self.it_hmacs_url(path_and_query)
      it "includes generated hmac param" do
        subject.hmac_helper
          .should_receive(:create)
          .with(path_and_query)
          .and_return("hmac-value")
        url.should include("hmac=hmac-value")
      end
    end

    def query_params(url)
      Rack::Utils.parse_query(URI.parse(url).query)
    end

    describe "#hmaced_url_for" do
      let(:url) { subject.hmaced_url_for("/path", {:param => "value"}, [:param]) }

      it_generates_url "/path"
      it_hmacs_url "/path?param=value"

      it "includes given params" do
        query_params(url)["param"].should == "value"
      end
    end

    describe "#instance_file_url_for" do
      let(:url) { subject.instance_file_url_for("instance-id", "/path-to-file") }
      before { Time.stub(:now => Time.at(10)) }

      it_generates_url "/instance_paths/instance-id"
      it_hmacs_url "/instance_paths/instance-id?path=%2Fpath-to-file&timestamp=10"

      it "includes timestamp with current time" do
        query_params(url)["timestamp"].should == "10"
      end

      it "includes file path" do
        query_params(url)["path"].should == "/path-to-file"
      end
    end

    describe "#staging_task_file_url_for" do
      let(:url) { subject.staging_task_file_url_for("task-id", "/path-to-file") }
      before { Time.stub(:now => Time.at(10)) }

      it_generates_url "/staging_tasks/task-id/file_path"
      it_hmacs_url "/staging_tasks/task-id/file_path?path=%2Fpath-to-file&timestamp=10"

      it "includes timestamp with current time" do
        query_params(url)["timestamp"].should == "10"
      end

      it "includes file path" do
        query_params(url)["path"].should == "/path-to-file"
      end
    end
  end

  describe "#verify_hmaced_url" do
    context "when hmac-ed path matches original path" do
      let(:verified_params) { [] }
      let(:url) { subject.hmaced_url_for("/path", {:param => "value"}, verified_params) }

      it "returns true" do
        subject.verify_hmaced_url(url, verified_params).should be_true
      end
    end

    context "when path does not match original path" do
      let(:verified_params) { [] }
      let(:url) { subject.hmaced_url_for("/path", {:param => "value"}, verified_params) }

      it "returns false" do
        url.sub!("/path", "/malicious-path")
        subject.verify_hmaced_url(url, verified_params).should be_false
      end
    end

    context "when hmac-ed params match original params" do
      let(:url) { subject.hmaced_url_for("/path", {:param1 => "value1", :param2 => "value2"}, verified_params) }

      context "when verifying all params" do
        let(:verified_params) { [:param1, :param2] }

        it "returns true" do
          subject.verify_hmaced_url(url, verified_params).should be_true
        end
      end

      context "when verifying specific params" do
        let(:verified_params) { [:param1] }

        it "returns true" do
          subject.verify_hmaced_url(url, verified_params).should be_true
        end
      end
    end

    context "when hmac-ed params are reordered" do
      let(:verified_params) { [:param1, :param2] }
      let(:url) { subject.hmaced_url_for("/path", {:param1 => "value", :param2 => "value"}, verified_params) }

      it "returns true" do
        url.sub!("param1", "paramX")
        url.sub!("param2", "param1")
        url.sub!("paramX", "param2")

        subject.verify_hmaced_url(url, verified_params).should be_true
      end
    end

    context "when hmac-ed param does not match original param" do
      let(:verified_params) { [:param] }
      let(:url) { subject.hmaced_url_for("/path", {:param => "value"}, verified_params) }

      it "returns false" do
        url.sub!("value", "malicious-value")
        subject.verify_hmaced_url(url, verified_params).should be_false
      end
    end

    context "when non-hmac-ed param is added (to support misc params additions)" do
      let(:verified_params) { [:param] }
      let(:url) { subject.hmaced_url_for("/path", {:param => "value"}, verified_params) }

      it "returns true" do
        url << "&new_param=new-value"
        subject.verify_hmaced_url(url, verified_params).should be_true
      end
    end

    context "when url does not have hmac param" do
      it "returns false" do
        subject.verify_hmaced_url("http://google.com", []).should be_false
      end
    end

    context "when passed url is not a valid url" do
      it "returns false" do
        subject.verify_hmaced_url("invalid-url", []).should be_false
      end
    end
  end
end

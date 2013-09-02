# Copyright (c) 2009-2012 VMware, Inc.

require File.expand_path("../spec_helper", __FILE__)

module VCAP::CloudController
  describe VCAP::CloudController::Models::AppStopEvent do
    it_behaves_like "a CloudController model", {
      :required_attributes => [
        :timestamp,
        :organization_guid,
        :organization_name,
        :space_guid,
        :space_name,
        :app_guid,
        :app_name,
      ],
      :db_required_attributes => [
        :timestamp,
        :organization_guid,
        :organization_name,
      ],
      :unique_attributes => [
        :app_run_id
      ],
      :disable_examples => :deserialization,
      :skip_database_constraints => true
    }

    describe "create_from_app" do
      context "on an org without billing enabled" do
        it "should do nothing" do
          Models::AppStopEvent.should_not_receive(:create)
          app = Models::App.make
          app.space.organization.billing_enabled = false
          app.space.organization.save(:validate => false)
          Models::AppStopEvent.create_from_app(app)
        end
      end

      context "on an org with billing enabled" do
        let(:app) { Models::App.make }

        before do
          app.space.organization.billing_enabled = true
          app.space.organization.save(:validate => false)
        end

        it "should create an app stop event using the run id from the most recently created start event" do
          Timecop.freeze do
            newest_by_time = Models::AppStartEvent.create_from_app(app)

            newest_by_sequence = Models::AppStartEvent.create_from_app(app)
            newest_by_sequence.timestamp = Time.now - 3600
            newest_by_sequence.save

            stop_event = Models::AppStopEvent.create_from_app(app)
            stop_event.app_run_id.should == newest_by_sequence.app_run_id
          end
        end

        it "should raise an exception if a corresponding AppStartEvent is not found" do
          expect { Models::AppStopEvent.create_from_app(app) }.to raise_error( VCAP::CloudController::Models::MissingAppStartEvent )
        end
      end
    end
  end
end

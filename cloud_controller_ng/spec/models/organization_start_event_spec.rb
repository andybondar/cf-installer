# Copyright (c) 2009-2012 VMware, Inc.

require File.expand_path("../spec_helper", __FILE__)

module VCAP::CloudController
  describe VCAP::CloudController::Models::OrganizationStartEvent do
    it_behaves_like "a CloudController model", {
      :required_attributes => [
        :timestamp,
        :organization_guid,
        :organization_name,
      ],
      :disable_examples => :deserialization
    }

    describe "create_from_org" do
      context "on an org without billing enabled" do
        it "should raise an error" do
          Models::OrganizationStartEvent.should_not_receive(:create)
          org = Models::Organization.make
          org.billing_enabled = false
          org.save(:validate => false)
          expect {
            Models::OrganizationStartEvent.create_from_org(org)
          }.to raise_error(Models::OrganizationStartEvent::BillingNotEnabled)
        end
      end

      # we don't/can't explicitly test the create path, because that
      # happens automatically when updating the billing_enabled flag
      # on the org. See the org model specs.
    end
  end
end

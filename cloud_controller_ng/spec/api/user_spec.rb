require File.expand_path("../spec_helper", __FILE__)

module VCAP::CloudController
  describe VCAP::CloudController::User do
    context 'logged in as an admin' do
      before do
        VCAP::CloudController::SecurityContext.stub(:token).and_return({'scope' => ['cloud_controller.admin']})
      end

      include_examples "uaa authenticated api", path: "/v2/users"
      include_examples "enumerating objects", path: "/v2/users", model: Models::User
      include_examples "reading a valid object", path: "/v2/users", model: Models::User, basic_attributes: []
      include_examples "operations on an invalid object", path: "/v2/users"
      include_examples "creating and updating", path: "/v2/users", model: Models::User, required_attributes: %w(guid), unique_attributes: %w(guid), extra_attributes: []
      include_examples "deleting a valid object", path: "/v2/users", model: Models::User, one_to_many_collection_ids: {}, one_to_many_collection_ids_without_url: {}
      include_examples "collection operations", path: "/v2/users", model: Models::User,
        one_to_many_collection_ids: {},
        many_to_one_collection_ids: {
          :default_space => lambda { |user|
            org = user.organizations.first || Models::Organization.make
            Models::Space.make(:organization => org)
          }
        },
        many_to_many_collection_ids: {
          organizations: lambda { |user| Models::Organization.make },
          managed_organizations: lambda { |user| Models::Organization.make },
          billing_managed_organizations: lambda { |user| Models::Organization.make },
          audited_organizations: lambda { |user| Models::Organization.make },
          spaces: lambda { |user|
            org = user.organizations.first || Models::Organization.make
            Models::Space.make(organization: org)
          },
          managed_spaces: lambda { |user|
            org = user.organizations.first || Models::Organization.make
            Models::Space.make(organization: org)
          },
          audited_spaces: lambda { |user|
            org = user.organizations.first || Models::Organization.make
            Models::Space.make(organization: org)
          }
        }
    end

    describe 'permissions' do
      include_context "permissions"
      before do
        @obj_a = member_a
        @obj_b = member_b
      end

      let(:creation_req_for_a) { Yajl::Encoder.encode(:guid => 'hi') }
      let(:update_req_for_a) { Yajl::Encoder.encode(:guid => @obj_a.guid) }

      context 'normal user' do
        let(:member_a) { @org_a_manager }
        let(:member_b) { @space_a_manager }
        include_examples "permission checks", "User",
                         :model => Models::User,
                         :path => "/v2/users",
                         :enumerate => :not_allowed,
                         :create => :not_allowed,
                         :read => :not_allowed,
                         :modify => :not_allowed,
                         :delete => :not_allowed
      end

      context 'admin user' do
        let(:member_a) { @org_a_manager }
        let(:member_b) { @space_a_manager }
        let(:enumeration_expectation_a) { Models::User.order(:id).limit(50) }
        let(:enumeration_expectation_b) { enumeration_expectation_a }

        before do
          VCAP::CloudController::SecurityContext.stub(:token).and_return({'scope' => ['cloud_controller.admin']})
        end

        include_examples "permission checks", "Admin",
                         :model => Models::User,
                         :path => "/v2/users",
                         :enumerate => Proc.new { Models::User.count },
                         :create => :allowed,
                         :read => :allowed,
                         :modify => :allowed,
                         :delete => :allowed,
                         :permissions_overlap => true
      end
    end
  end
end

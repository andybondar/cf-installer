require "cloud_controller/encryptor"

module VCAP::CloudController
  module ModelSpecHelper
    shared_examples "a model with an encrypted attribute" do
      before do
        Config.stub(:db_encryption_key).and_return("correct-key")
      end

      def new_model
        model_class.make.tap do |model|
          model.update(encrypted_attr => value_to_encrypt)
        end
      end

      let(:model_class) { described_class }
      let(:value_to_encrypt) { "this-is-a-secret" }
      let!(:model) { new_model }

      def last_row
        model_class.dataset.naked.order_by(:id).last
      end

      it "is encrypted before being written to the database" do
        saved_attribute = last_row[encrypted_attr]
        saved_attribute.should_not include value_to_encrypt
      end

      it "is decrypted when it is read from the database" do
        model_class.last.refresh.send(encrypted_attr).should == value_to_encrypt
      end

      it "uses the db_encryption_key from the config file" do
        saved_attribute = last_row[encrypted_attr]

        expect(
          Encryptor.decrypt(saved_attribute, model.salt)
        ).to include(value_to_encrypt)

        expect {
          Config.stub(:db_encryption_key).and_return("a-totally-different-key")
          Encryptor.decrypt(saved_attribute, model.salt)
        }.to raise_error(OpenSSL::Cipher::CipherError)
      end

      it "uses a salt, so that every row is encrypted with a different key" do
        value_with_original_salt = last_row[encrypted_attr]
        new_model
        expect(value_with_original_salt).not_to eql(last_row[encrypted_attr])
      end
    end
  end
end
require File.expand_path("../spec_helper", __FILE__)

module VCAP::CloudController
  describe Encryptor do
    let(:salt) { Encryptor.generate_salt }

    describe "generating some salt" do
      it "returns a short, random string" do
        expect(salt.length).to eql(8)
        expect(salt).not_to eql(Encryptor.generate_salt)
      end
    end

    describe "encrypting a string" do
      let(:input) { "i-am-the-input" }
      let!(:encrypted_string) { Encryptor.encrypt(input, salt) }

      it "returns an encrypted string" do
        expect(encrypted_string).to match(/\w+/)
        expect(encrypted_string).not_to include(input)
      end

      it "is deterministic" do
        expect(Encryptor.encrypt(input, salt)).to eql(encrypted_string)
      end

      it "depends on the salt" do
        expect(Encryptor.encrypt(input, Encryptor.generate_salt)).not_to eql(encrypted_string)
      end

      it "depends on the db_encryption_key from the CC config file" do
        VCAP::CloudController::Config.stub(:db_encryption_key).and_return("a-totally-different-key")
        expect(Encryptor.encrypt(input, salt)).not_to eql(encrypted_string)
      end

      describe "decrypting the string" do
        it "returns the original string" do
          expect(Encryptor.decrypt(encrypted_string, salt)).to eq(input)
        end
      end
    end
  end
end
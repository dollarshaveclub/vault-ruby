require "spec_helper"

module Vault
  describe Authenticate do
    let(:auth) { Authenticate.new(client: nil) }
    describe "#region_from_sts_endpoint" do
      subject { auth.send(:region_from_sts_endpoint, sts_endpoint) }

      context 'with a china endpoint' do
        let(:sts_endpoint) { "https://sts.cn-north-1.amazonaws.com.cn" }
        it { is_expected.to eq 'cn-north-1' }
      end

      context 'with a GovCloud endpoint' do
        let(:sts_endpoint) { "https://sts.us-gov-west-1.amazonaws.com" }
        it { is_expected.to eq 'us-gov-west-1' }
      end

      context 'with no regional endpoint' do
        let(:sts_endpoint) { "https://sts.amazonaws.com" }
        it { is_expected.to eq 'us-east-1' }
      end

      context 'with a malformed url' do
        let(:sts_endpoint) { "https:sts.amazonaws.com" }
        it { expect { subject }.to raise_exception(StandardError, "Unable to parse STS endpoint https:sts.amazonaws.com") }
      end
    end

    describe "#kubernetes" do
      let(:client) { Vault::Client.new }
      let(:auth) { Authenticate.new(client) }
      let(:role) { "valid_role" }
      let(:jwt_token) { "valid_jwt_token" }
      let(:client_token) { "valid_client_token" }
      let(:request_payload) { JSON.fast_generate({role: role, jwt: jwt_token}) }
      let(:response_payload) { {auth: {client_token: client_token}} }
      let(:k8s_auth_path) { "new-cluster"}
      
      context 'with valid role and jwt_token' do
        it "should set Vault::Client.token" do
          allow(client).to receive(:post).with("/v1/auth/kubernetes/login", request_payload).and_return(response_payload)
          auth.send(:kubernetes, role, jwt_token)
          expect(client.token).to eq(client_token)
        end

        it "should post to kubernetes login endpoint" do
          expect(client).to receive(:post).with("/v1/auth/kubernetes/login", request_payload).and_return(response_payload)
          auth.send(:kubernetes, role, jwt_token)
        end
      end

      context 'with optional k8s_auth_path' do
        it "should allow optional k8s_auth_path when setting Vault::Client.token" do 
          allow(client).to receive(:post).with("/v1/auth/#{k8s_auth_path}/login", request_payload).and_return(response_payload)
          auth.send(:kubernetes, role, jwt_token, { k8s_auth_path: k8s_auth_path })
          expect(client.token).to eq(client_token)
        end
    
        it "should post to the optional k8s auth endpoint" do 
          expect(client).to receive(:post).with("/v1/auth/#{k8s_auth_path}/login", request_payload).and_return(response_payload)
          auth.send(:kubernetes, role, jwt_token, { k8s_auth_path: k8s_auth_path })
        end

      end
    end
  end
end

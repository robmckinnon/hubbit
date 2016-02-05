require_relative '../spec_helper'
require_relative '../../lib/hubbit'
require_relative '../fixtures/user_response'
require_relative '../fixtures/org_response'
require_relative '../fixtures/repos_response'

RSpec.describe Hubbit do

  let(:user_response_hash) { $user_response }
  let(:user_response_json) { user_response_hash.to_json }

  let(:repos_response_array) { $repos_response }
  let(:repos_response_json) { repos_response_array.to_json }

  let(:repo_response_hash) { $repos_response.first }
  let(:repo_response_json) { repo_response_hash.to_json }

  let(:org_response_hash) { $org_response }
  let(:org_response_json) { org_response_hash.to_json }

  before do
    stub_request(:get, user_response_hash[:url]).
       to_return(status: 200, headers: {}, body: user_response_json)
  end

  let(:user) { Hubbit.user user_response_hash[:login] }

  shared_examples 'populate object' do |type|
    let(:object) { send(type) }
    let(:response_hash) { send(:"#{type}_response_hash") }

    it "creates #{type}" do
      expect(object).to be_a("Hubbit::#{type.capitalize}".constantize)
    end

    it "assigns data to attributes on #{type}" do
      response_hash.each do |field, value|
        expect(object.send(field)).to eq value unless value.blank? || value.is_a?(Hash)
      end
    end

    it "creates _ accessor methods on #{type} for _url attributes" do
      url_fields = response_hash.keys.select {|k| k[/_url$/]}
      url_fields.each do |url_field|
        _accessor = "_#{url_field.to_s.chomp('_url')}".to_sym
        expect(object.methods).to include(_accessor) unless url_field[/(avatar|html|git|clone|ssh|svn|mirror)_url/]
      end
    end
  end

  describe 'retrieve user data' do
    include_examples 'populate object', :user
  end

  describe 'retrieve further data' do
    before do
      stub_request(:get, user_response_hash[:repos_url]).
         to_return(status: 200, headers: {}, body: repos_response_json)
    end

    let(:repo) { user._repos.first }

    include_examples 'populate object', :repo

    it 'creates object for even further data obtained via *_url fields' do
      expect(repo.owner).to be_a(Hubbit::Owner)
    end
  end

  describe 'retrieve organisation data' do
    before do
      stub_request(:get, org_response_hash[:url]).
        to_return(status: 200, headers: {}, body: org_response_json)
    end

    let(:org) { Hubbit.org org_response_hash[:login] }

    include_examples 'populate object', :org
  end

  describe 'retrieve repo data' do
    before do
      stub_request(:get, repo_response_hash[:url]).
        to_return(status: 200, headers: {}, body: repo_response_json)
    end

    let(:repo) { Hubbit.repo repo_response_hash[:full_name] }

    include_examples 'populate object', :repo
  end

end

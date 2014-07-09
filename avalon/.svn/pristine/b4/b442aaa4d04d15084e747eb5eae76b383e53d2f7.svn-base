require 'spec_helper'

describe Permalink do

  describe '#permalink' do
    
    let(:master_file){ FactoryGirl.build(:master_file) }

    context 'permalink does not exist' do
      it 'returns nil' do
        expect(master_file.permalink).to be_nil
      end

      it 'returns nil with query variables' do 
        expect(master_file.permalink({a:'b'})).to be_nil
      end
    end

    context 'permalink exists' do
      
      let(:permalink_url){ "http://permalink.com/object/#{master_file.pid}" }
      
      before do 
        master_file.add_relationship(:has_permalink, permalink_url, true)
      end
      
      it 'returns a string' do
        expect(master_file.permalink).to be_kind_of(String)
      end
      
      it 'appends query variables to the url' do
        query_var_hash = { urlappend: '/embed' }
        expect(master_file.permalink(query_var_hash)).to eq("#{permalink_url}?#{query_var_hash.to_query}")
      end
    end

  end
end
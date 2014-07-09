require 'spec_helper'

describe Avalon::AccessControls::Hidden do

  before do
    class Foo < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Avalon::AccessControls::Hidden
    end
  end

  subject { Foo.new }

  describe "hidden" do
    it "should default to discoverable" do
      expect(subject.hidden?).to be_falsey
      expect(subject.to_solr["hidden_bsi"]).to be_falsey
    end

    it "should set hidden?" do
      subject.hidden = true
      expect(subject.hidden?).to be_truthy
      expect(subject.to_solr["hidden_bsi"]).to be_truthy
    end
  end
end

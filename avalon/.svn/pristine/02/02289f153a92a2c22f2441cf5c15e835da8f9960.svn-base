# Copyright 2011-2013, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
# 
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed 
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the 
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---

require 'spec_helper'

describe ApplicationHelper do
  describe "#active_for_controller" do
    before(:each) do
      allow(helper).to receive(:params).and_return({controller: 'media_objects'})
    end
    it "should return 'active' for matching controller names" do
      expect(helper.active_for_controller('media_objects')).to eq('active')
    end
    it "should return '' for non-matching controller names" do
      expect(helper.active_for_controller('master_files')).to eq('')
    end
    it "should handle name-spaced controllers" do
      allow(helper).to receive(:params).and_return({controller: 'admin/groups'})
      expect(helper.active_for_controller('admin/groups')).to eq('active')
      expect(helper.active_for_controller('groups')).to eq('')
    end
  end

  describe "#stream_label_for" do
    it "should return the label first if it is available" do
      master_file = FactoryGirl.build(:master_file, label: 'Label')
      expect(master_file.file_location).not_to be_nil
      expect(master_file.label).not_to be_nil
      expect(helper.stream_label_for(master_file)).to eq('Label')
    end
    it "should return the filename second if it is available" do
      master_file = FactoryGirl.build(:master_file, label: nil)
      expect(master_file.file_location).not_to be_nil
      expect(master_file.label).to be_nil
      expect(helper.stream_label_for(master_file)).to eq(File.basename(master_file.file_location))
    end
    it "should handle empty file_locations and labels" do
      master_file = FactoryGirl.build(:master_file, file_location: nil, label: nil)
      expect(master_file.file_location).to be_nil
      expect(master_file.label).to be_nil
      expect(helper.stream_label_for(master_file)).to eq(master_file.pid)
    end
  end

  describe "#search_result_label" do
    it "should not include a duration string if it would be 0" do
      media_object = FactoryGirl.create(:media_object)
      expect(helper.search_result_label(media_object.to_solr)).not_to include("(00:00)")
    end
  end
end

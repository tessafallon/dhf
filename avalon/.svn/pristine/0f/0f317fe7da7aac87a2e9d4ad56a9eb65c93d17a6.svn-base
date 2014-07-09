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

describe MasterFilesController do
  describe "#create" do
    let!(:media_object) {FactoryGirl.create(:media_object)}
    let!(:content_provider) {login_user media_object.collection.managers.first}

    context "must provide a container id" do
      it "should fail if no container id provided" do
        request.env["HTTP_REFERER"] = "/"
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
             
        expect { post :create, Filedata: [@file], original: 'any'}.not_to change { MasterFile.count }
      end
    end
     
    context "cannot upload a file over the defined limit" do
     it "should provide a warning about the file size" do
      request.env["HTTP_REFERER"] = "/"
            
      @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
      allow(@file).to receive(:size).and_return(MasterFile::MAXIMUM_UPLOAD_SIZE + 2^21)  
     
      expect { post :create, Filedata: [@file], original: 'any', container_id: media_object.pid}.not_to change { MasterFile.count }
     
      expect(flash[:error]).not_to be_nil
     end
    end
     
    context "must be a valid MIME type" do
      it "should recognize a video format" do
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        post :create, 
          Filedata: [@file], 
          original: 'any', 
          container_id: media_object.pid 

        master_file = media_object.reload.parts.first
        expect(master_file.file_format).to eq "Moving image" 
             
        expect(flash[:errors]).to be_nil
      end
           
     it "should recognize an audio format" do
       @file = fixture_file_upload('/jazz-performance.mp3', 'audio/mp3')
       post :create, 
         Filedata: [@file], 
         original: 'any', 
         container_id: media_object.pid 

       master_file = media_object.reload.parts.first
       expect(master_file.file_format).to eq "Sound" 
     end
       
     it "should reject non audio/video format" do
       request.env["HTTP_REFERER"] = "/"
     
       @file = fixture_file_upload('/public-domain-book.txt', 'application/json')
        allow(Rubyhorn).to receive_message_chain(:client,:stop).and_return(true)

       expect { post :create, Filedata: [@file], original: 'any', container_id: media_object.pid }.not_to change { MasterFile.count }
     
       expect(flash[:error]).not_to be_nil
     end
    
     it "should recognize audio/video based on extension when MIMETYPE is of unknown format" do
       @file = fixture_file_upload('/videoshort.mp4', 'application/octet-stream')
    
       post :create, 
         Filedata: [@file], 
         original: 'any', 
         container_id: media_object.pid 
       master_file = MasterFile.all.last
       expect(master_file.file_format).to eq "Moving image" 
             
       expect(flash[:errors]).to be_nil
     end
    end
     
    context "should process file successfully" do
      it "should associate with a MediaObject" do
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        #Work-around for a Rails bug
        class << @file
          attr_reader :tempfile
        end
   
        post :create, Filedata: [@file], original: 'any', container_id: media_object.pid
         
        master_file = MasterFile.all.last
        expect(media_object.reload.parts).to include master_file
        expect(master_file.mediaobject.pid).to eq(media_object.pid)
         
        expect(flash[:errors]).to be_nil        
      end
      it "should associate a dropbox file" do
        allow_any_instance_of(Avalon::Dropbox).to receive(:find).and_return "spec/fixtures/videoshort.mp4"
        post :create, dropbox: [{id: 1}], original: 'any', container_id: media_object.pid

        master_file = MasterFile.all.last
        expect(media_object.reload.parts).to include master_file
        expect(master_file.mediaobject.pid).to eq(media_object.pid)

        expect(flash[:errors]).to be_nil
      end
    end

    context "should have default permissions" do
      it "should set edit_user and edit_group" do
        @file = fixture_file_upload('/videoshort.mp4', 'video/mp4')
        #Work-around for a Rails bug
        class << @file
          attr_reader :tempfile
        end
   
        post :create, Filedata: [@file], original: 'any', container_id: media_object.pid
        master_file = MasterFile.all.last
        expect(master_file.edit_groups).to include "collection_manager"
        expect(master_file.edit_users).to include content_provider.username
      end
    end
  end
  
  describe "#update" do
    let!(:master_file) {FactoryGirl.create(:master_file)}

    context "should handle Matterhorn pingbacks" do
      it "should create Derivatives when processing succeeded" do
        #stub Rubyhorn call and return a workflow fixture and check that Derivative.create_from_master_file is called
        xml = File.new("spec/fixtures/matterhorn_workflow_doc.xml")
        doc = Rubyhorn::Workflow.from_xml(xml)
        allow(Rubyhorn).to receive_message_chain(:client,:instance_xml).and_return(doc)
        allow(Rubyhorn).to receive_message_chain(:client,:get).and_return(nil)
        allow(Rubyhorn).to receive_message_chain(:client,:stop).and_return(true)
        #Thumbnail and poster datastreams must have some content for saving to succeed
        master_file.thumbnail.mimeType = 'image/png'
        master_file.thumbnail.content = 'PNG'
        master_file.poster.mimeType = 'image/png'
        master_file.poster.content = 'PNG'
        master_file.save 
        put :update, id: master_file.pid, workflow_id: 1103

        master_file.reload 
        expect(master_file.derivatives.count).to eq(3)
      end
    end
  end
  
  describe "#destroy" do
    let!(:master_file) {FactoryGirl.create(:master_file)}

    before(:each) do
      login_user master_file.mediaobject.collection.managers.first
      allow(Rubyhorn).to receive_message_chain(:client,:stop).and_return(true) 
    end

    context "should be deleted" do
      it "should no longer exist" do
        expect { post :destroy, id: master_file.pid }.to change { MasterFile.count }.by(-1)
      end
    end
    
    context "should no longer be associated with its parent object" do
      it "should create then remove a file from a video object" do
        expect { post :destroy, id: master_file.pid }.to change { MasterFile.count }.by(-1)
        expect(master_file.mediaobject.reload.parts).not_to include master_file         
      end
    end
  end

  describe "#show" do
    let!(:master_file) {FactoryGirl.create(:master_file)}
    it "should redirect you to the media object page with the correct section" do
      get :show, id: master_file.pid 
      expect(response).to redirect_to(pid_section_media_object_path(master_file.mediaobject.pid, master_file.pid)) 
    end
  end
  
end

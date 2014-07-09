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

describe Comment do 
  subject(:comment) {Comment.new(name: "Example", subject: "Other", email: "example@example.com", email_confirmation: "example@example.com", comment: "Example Comment")}
  
  it {should validate_presence_of(:name).with_message("Name is a required field")}
  it {should validate_presence_of(:subject).with_message("Choose a subject from the dropdown menu")}
  it {should ensure_inclusion_of(:subject).in_array(Comment::SUBJECTS).with_message("Choose a subject from the dropdown menu")}
  it {should validate_presence_of(:comment).with_message("Provide a comment before submitting the form")}
  it "should fail if a captcha value is entered" do
    should_not_receive :nickname
  end

  context "Email address" do
    it {should validate_presence_of(:email).with_message("Email address is a required field")}
    it {should validate_confirmation_of(:email)}
    it {should allow_value("example@example.com").for(:email)}
    it {should_not allow_value("example@").for(:email)}
    it {should_not allow_value("example").for(:email)}
  end

  describe "Comments" do
    it "should call scrub_comment" do
      comment.should_receive(:scrub_comment)
      comment.valid?
    end 
  end

  describe "#scrub_comment" do
    it "should scrub the comment" do
      comment.comment = 
        "<script>alert('This would be an exploit')</script><p>But this is safe</p>"
      comment.scrub_comment
      comment.comment.should_not match /\<script\>.*\<\\script\>/
    end
  end  
end

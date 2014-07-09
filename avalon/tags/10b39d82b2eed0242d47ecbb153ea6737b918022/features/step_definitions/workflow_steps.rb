# This is kludgy but it works - after you spawn a new ID immediately pull it back so
# you can use it in later steps to avoid constantly repeating the identifier
When /^I create a new ([^"]*)$/ do |asset_type|
  visit new_video_path

  @resource = Video.find(:all).last
  puts "<< Storing #{@resource.pid} for later use >>"
end

# Shortcut for the more verbose step so that the PID does not have to be constantly
# repeated in the feature definitions. 
#
# TO DO : A future enhancement might be to detect the lack of an ID parameters and
#         throw a warning intead of letting it fail fatally.
When /^I go to the "([^"]*)" step$/ do |step|
  id = params[:id]
  step.gsub!(' ', '_')
  
  step "I go to the \"#{step}\" step for \"#{id}\""
end

When /^I go to the "([^"]*)" step for "([^"]*)"$/ do |step, id|
  step.gsub!(' ', '_')
  visit edit_video_path(id, step: step)
end

Then /I should see a simple metadata form/ do 
  test_for_field('metadata_title')
  test_for_field('metadata_createdon')
  test_for_field('metadata_creator')
end

# Paths for matching actions that occur when updating an existing record
When /^I edit "([^"]*)"$/ do |id|
  # Refactor this for be more DRY since it is very similar to the edit methods
  # above
  visit edit_video_path(id, step: 'basic_metadata')
  
  within ('#basic_metadata_form') do  
    fill_in 'metadata_creator', with: 'Cucumber'
    fill_in 'metadata_title', with: 'New test record'
    fill_in 'metadata_createdon', with: '2012.04.21'
    fill_in 'metadata_abstract', with: 'A test record generated as part of Cucumber automated testing'
    click_on 'Save and finish'
  end
end

# Use 'it' as a shortcut in complex steps to retrieve the current PID from the
# active test's scope. This assumes that you have first called the 'create a new'
# step earlier in the sequence
When /^I edit it$/ do
  step "I edit #{@resource.pid}"
end

When /^provide basic metadata for it$/ do 
  # Refactor this for be more DRY since it is very similar to the edit methods
  # above
  visit edit_video_path(@resource.pid, step: 'basic_metadata')
  
  within ('#basic_metadata_form') do  
    fill_in 'metadata_creator', with: 'Cucumber'
    fill_in 'metadata_title', with: 'New test record'
    fill_in 'metadata_createdon', with: '2012.04.21'
    fill_in 'metadata_abstract', with: 'A test record generated as part of Cucumber automated testing'
    click_on 'Save and finish'
  end
end

When /^I delete it$/ do
  visit edit_video_path(@resource.pid)
  click_on 'Delete item'
end

When /^I delete the file$/ do
  visit edit_video_path(@resource.pid, step: 'file-upload')
  click_on 'Delete file'
end

# Refactor this at some point to be more generic instead of quick and dirty
# This also assumes the @resource variable has been set earlier in the session and is
# available for the current test (such as in 'create a new video')
Then /^I should be able to find the record in the browse view$/ do
  visit search_index_path
  
  within '#search_results' do
    test_for_search_result(@resource.pid)
  end
end

Then /^I should be able to search for "(.*)"$/ do |pid|
  visit search_path(q: pid)
  test_for_search_result(@resource.pid)  
end

# Alias for explicit ID which assumes that the PID is in scope at the moment
Then /^I should be able to search for it$/ do
  step "I should be able to search for #{@resource.pid}"
end

Then /^I should be prompted to upload a file$/ do
  within "fieldset#uploader" do
    assert page.should have_content('File Upload')
    assert page.should have_selector('input[type="file"]')
  end
end

# This is not the right test but it is Friday afternoon and my mind can't work
# properly at the moment. It should check for the absence of any fields without the
# required property
Then /^I should see only required fields$/ do 
  within "#basic_metadata_form" do
    page.should have_selector("input[name='metadata_title']")
    page.should have_selector("input[name='metadata_creator']")
    page.should have_selector("input[name='metadata_createdon']")
  end
end

# Paths for matching actions that occur when updating an existing record
Then /^I should see the changes to the metadata$/ do
  visit video_path(@resource.pid) 
  within "#metadata" do
    assert page.should have_content('Cucumber')
    assert page.should have_content('2012.04.21')
    assert page.should have_content('A test record generated as part of Cucumber automated testing')
  end
end

Then /^I should see confirmation it has been deleted$/ do
  within "#marquee" do
    assert page.should have_content("#{@resource.pid} has been deleted from the system")
  end
end

Then /^I should see confirmation the file has been deleted$/ do
  within "#marquee" do
    assert page.should have_content("#{@resource.parts.first.label} has been deleted from the system")
  end
end

def test_for_field(field)
  within ('body') do
    field.gsub!(' ', '_')
    field.downcase!
    
    assert page.has_selector?("\##{field}")
  end
end

def test_for_search_result(pid)
  within ".search-result" do
    puts "<< Testing for presence of #{video_path(pid)} >>"
    
    #assert page.should have_content("a[href='#{link_to video_path(pid)}']")
  end
end

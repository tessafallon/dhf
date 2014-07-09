module ControllerMacros
  def login_as_archivist
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    sign_in FactoryGirl.create(:cataloger) # Using factory girl as an example
  end

  def login_as(role = 'student')
    @request.env["devise.mapping"] = Devise.mappings[role]
    user = FactoryGirl.create(role)
    
    puts "<< USER INFORMATION >>"
    puts user
    
    sign_in user
  end
end


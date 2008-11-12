module UsersHelper
  def add_identity_link(name) 
    link_to_function name do |page| 
      page.insert_html :bottom, :identities, :partial => 'identity', :object => Identity.new 
    end 
  end 
end

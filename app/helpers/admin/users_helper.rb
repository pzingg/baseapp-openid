module Admin::UsersHelper
  def index_title
    !params[:initial].blank? ? "Users Named #{params[:initial].upcase}" :
      (controller.action_name == 'index' ? "All Users" : "#{controller.action_name.humanize} Users")
  end
  
  def users_by_names_and_states
    names = Profile.find(:all, :select => 'DISTINCT SUBSTRING(last_name,1,1) AS initial').collect do |p|
      p.initial
    end.sort
    index_states = { 'unapproved' => 1, 'pending' => 2,  'active' => 3, 'suspended' => 4, 'deleted' => 5}
    states = User.find(:all, :select => 'DISTINCT state', 
      :conditions => ['state in (?)', index_states.keys]).collect do |u|
      u.state
    end.sort { |a, b| index_states[a] <=> index_states[b] }
    by_name_links = names.collect do |name|
      link_to(name.upcase, admin_users_by_name_path(name.downcase))
    end
    by_state_links = states.collect do |state|
      link_to(state.humanize, "#{admin_users_path}/#{state}")
    end
    ([link_to('All', admin_users_path)] + by_name_links + by_state_links).join(' ')
  end
end

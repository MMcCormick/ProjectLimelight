

prefix = "/opt/#{node[:torquebox][:version]}"
current = "/opt/torquebox-current"

user "torquebox" do
  comment "torquebox"
  system  "true"
  shell   "/bin/false"
end

puts node[:torquebox][:url]

#execute "install torquebox gem" do
#  command "jruby -J-Xmx1024m -S gem install torquebox-server --pre --source http://torquebox.org/2x/builds/LATEST/gem-repo"
#end

execute "fetch torquebox" do
    cwd "/tmp"
    command "wget #{node[:torquebox][:url]}"
    not_if { FileTest.exists?("/tmp/#{node[:torquebox][:file_name]}.zip") }
end

execute "unzip /tmp/#{node[:torquebox][:file_name]}.zip" do
  command "cd /tmp; unzip -q #{node[:torquebox][:file_name]}.zip -d /opt"
  not_if { FileTest.directory?(prefix) }
end

template "/etc/profile.d/torquebox.sh" do
  mode "755"
  source "torquebox.erb"
end

execute "create symbolic link to new torquebox" do
  command "rm #{current}; ln -s #{prefix} #{current}"
end

# install upstart
#execute "torquebox-upstart" do
  #command "cd #{current}; rake torquebox:upstart:install"
  #command "rake torquebox:upstart:install"
  #creates "/etc/init/torquebox.conf"
  #cwd current
  #action :run
  #environment({
  #  'TORQUEBOX_HOME'=> current,
  #  'JBOSS_HOME'=> "#{current}/jboss",
  #  'JRUBY_HOME'=> "#{current}jruby",
  #  'PATH' => "#{ENV['PATH']}:#{current}/jruby/bin"
  #})
#end



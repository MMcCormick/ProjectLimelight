# Configure the TorqueBox Servlet-based session store.
# Provides for server-based, in-memory, cluster-compatible sessions
ProjectLimelight::Application.config.session_store :torquebox_store
if ENV['TORQUEBOX_APP_NAME']
  ProjectLimelight::Application.config.session_store :torquebox_store
else
  ProjectLimelight::Application.config.session_store :cookie_store, :key => '_limelight'
end  

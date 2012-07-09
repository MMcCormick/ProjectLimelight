require "omnicontacts"

Rails.application.middleware.use OmniContacts::Builder do
  importer :gmail, "878681641011-539hes1hlj5t55qte7hmg9jk6113va14.apps.googleusercontent.com", "RRXSZ7AWo9By3CYENka3RsEj", {:redirect_path => "/contacts/gmail/callback"}
  #importer :yahoo, "consumer_id", "consumer_secret", {:callback_path => '/callback'}
  #importer :hotmail, "client_id", "client_secret"
end
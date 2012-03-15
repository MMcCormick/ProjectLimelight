collection @increases

attributes :amount, :reason

node :id do |increase|
  increase.topic_id
end

child :topic => :topic do
  extends "topics/show"
end
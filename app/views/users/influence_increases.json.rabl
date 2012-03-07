collection @increases

attributes :amount, :topic_id

child :topic => :topic do
  extends "topics/show"
end
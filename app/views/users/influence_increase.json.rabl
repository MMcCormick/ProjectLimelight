object @increase

attributes :id, :amount, :reason

child :topic => :topic do
  extends "topics/show"
end
class Vote
  include Mongoid::Document

  field :amount
  embedded_in :votable, polymorphic: true

end
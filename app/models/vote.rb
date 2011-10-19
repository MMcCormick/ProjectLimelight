class Vote
  include Mongoid::Document

  field :amount
  embedded_in :votable, polymorphic: true

  validates :amount, :presence => true, :numericality => { :only_integer => true, :greater_than_or_equal_to => -1, :less_than_or_equal_to => 1 }
end
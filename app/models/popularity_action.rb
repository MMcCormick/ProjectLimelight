class PopularityAction
  include Mongoid::Document

  field :t, :as => :type
  field :st, :as => :subtype
  field :uid, :as => :user_id
  field :oid, :as => :object_id
  field :et, :as => :epoch_time

  embeds_many :pop_snippets, :as => :pop_ac_snip

  index({ :et => -1 })

  belongs_to :user

  validates_presence_of :type, :user_id, :object_id

  attr_accessible :type, :subtype, :object_id

  before_create :set_time

  def set_time
    self.epoch_time = Time.now.to_i
  end
end
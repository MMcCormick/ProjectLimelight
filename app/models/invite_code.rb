require 'securerandom'

class InviteCode
  include Mongoid::Document
  include Mongoid::CachedJson
  include Mongoid::Timestamps::Updated

  cache

  field :code
  field :allotted, :type => Integer
  field :used, :type => Integer, :default => 0

  validates_presence_of :code, :allotted
  validates_uniqueness_of :code
  validates_numericality_of :allotted

  attr_protected :used

  before_validation :generate

  belongs_to :user

  index :code

  def created_at
    id.generation_time
  end

  def generate
    if self.code.blank?
      self.code = SecureRandom.hex(3)
      while InviteCode.where(:code => self.code).first
        self.code = SecureRandom.hex(3)
      end
    end
  end

  def remaining
    allotted - used
  end

  def usable?
    used < allotted
  end

  def redeem
    self.used += 1
    save
  end

  json_fields \
    :code => { :properties => :short, :versions => [ :v1 ] },
    :allotted => { :properties => :short, :versions => [ :v1 ] },
    :used => { :properties => :short, :versions => [ :v1 ] }
end
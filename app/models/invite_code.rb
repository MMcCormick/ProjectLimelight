class InviteCode
  include Mongoid::Document
  include Mongoid::Timestamps

  field :code
  field :allotted, :type => Integer
  field :used, :type => Integer, :default => 0
  field :user_id

  validates_presence_of :code, :allotted
  validates_uniqueness_of :code
  validates_numericality_of :allotted

  attr_protected :used

  before_validation :generate

  def generate
    if self.code.blank?
      self.code = ActiveSupport::SecureRandom.hex(3)
      while InviteCode.first(conditions: {:code => self.code})
        self.code = ActiveSupport::SecureRandom.hex(3)
      end
    end
  end

  def usable?
    used < allotted
  end

  def redeem
    self.used += 1
    save
  end
end
#require 'json'
#
#class SmDestroyUser
#  include Resque::Plugins::UniqueJob
#
#  @queue = :soulmate
#
#  def self.perform(user_id)
#    Soulmate::Loader.new("user").remove({'id' => user_id})
#  end
#end
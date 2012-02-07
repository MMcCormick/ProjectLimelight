require 'jruby'
org.jruby.ext.fiber.FiberExtLibrary.new.load(JRuby.runtime, false)
class org::jruby::ext::fiber::ThreadFiber
  field_accessor :state
end

class Fiber
  def alive?
    JRuby.reference(self).state != org.jruby.ext.fiber.ThreadFiberState::FINISHED
  end
end
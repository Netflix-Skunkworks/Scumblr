require 'zeus/rails'

class CustomPlan < Zeus::Rails
end

Zeus.plan = CustomPlan.new

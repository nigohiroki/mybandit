class Arm

  attr_accessor :ctr, :cpc, :count

  def initialize(ctr = 0.5, cpc = 1.5)
    @ctr   = ctr
    @cpc   = cpc
    @count = 0
  end

  def change_ctr(ctr)
    @ctr = ctr
  end

  def revenue(disp)
    ((disp*@ctr)/100)*@cpc
  end

  # for softmax
  def weighted_avg(arms, tau)
    Math.exp(@ctr/tau)/(Arm.arm_ctrs(arms, tau).inject(:+))
  end
  def self.arm_ctrs(arms, tau)
    arms.each_with_object([]) do |a, ctrs|
      ctrs << Math.exp(a.ctr/tau)
    end
  end

  # for ucb
  def add_count(imp)
    @count += imp
  end
  def heuristic_ucb(totalCount)
    totalCount = 2 if totalCount == 0
    @ctr + (Math.sqrt(2*Math.log(totalCount)))/@count
  end
end

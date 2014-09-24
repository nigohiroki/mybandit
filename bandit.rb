require './arm.rb'

class Bandit
  #初期値
  CPC         = 1.5
  INITIAL_CTR = { "arm0" => 0.7, "arm1" => 0.8, "arm2" => 0.6, "arm3" => 0.5 }
  #INITIAL_CTR = { "arm0" => 0.5, "arm1" => 0.5, "arm2" => 0.5, "arm3" => 0.5 }
  ARM_NUM     = 4
  MAX_IMP     = 10_000_000
  STEP_IMP    =    100_000

  def epsilon_greedy
    epsilon   = 0.5
    init_rate = [25, 25, 25, 25]
    exploit_rate  = init_rate
    explore_rate  = init_rate
    exploit       = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
    explore       = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
    explore_total = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
    arms          = Array.new
    ARM_NUM.times do |i|
      arms << Arm.new(INITIAL_CTR["arm#{i}"], CPC)
    end
    0.step(MAX_IMP, STEP_IMP) do |imp|
      #探索用レートの初期化
      explore_rate = [25, 25, 25, 25]
      ARM_NUM.times do |i|
        #CTR変更
        arms[i].change_ctr((INITIAL_CTR["arm#{i}"] + tremor_ctr).round(1))
        #活用revenue and 探索revenue
        exploit["arm#{i}"] += arms[i].revenue(((STEP_IMP*(1 - epsilon))*exploit_rate[i])/100)
        explore["arm#{i}"]  = arms[i].revenue(((STEP_IMP*epsilon)*explore_rate[i])/100)
        explore_total["arm#{i}"] += explore["arm#{i}"]
        arms[i].add_count(((STEP_IMP*(1 - epsilon))*exploit_rate[i])/100 + ((STEP_IMP*epsilon)*explore_rate[i])/100)
      end
      exploit_rate = change_exploit_rate(exploit_rate, check_revenue(explore))
    end
    arms.each_with_object([]) do |a, arms_count|
      arms_count << a.count.to_i
    end
  end

  def softmax
    tau       = 0.1
    epsilon   = 0.1
    init_rate = [25, 25, 25, 25]
    exploit_rate  = init_rate
    explore_rate  = init_rate
    exploit       = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
    explore       = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
    explore_total = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
    arms          = Array.new
    ARM_NUM.times do |i|
      arms << Arm.new(INITIAL_CTR["arm#{i}"], CPC)
    end
    0.step(MAX_IMP, STEP_IMP) do |imp|
      #探索用レートの初期化
      ARM_NUM.times do |i|
        explore_rate[i] = (arms[i].weighted_avg(arms, tau) * 100).round(1)
      end
      ARM_NUM.times do |i|
        #CTR変更
        arms[i].change_ctr((INITIAL_CTR["arm#{i}"] + tremor_ctr).round(1))
        #活用revenue and 探索revenue
        exploit["arm#{i}"] += arms[i].revenue(((STEP_IMP*(1 - epsilon))*exploit_rate[i])/100)
        explore["arm#{i}"]  = arms[i].revenue(((STEP_IMP*epsilon)*explore_rate[i])/100)
        explore_total["arm#{i}"] += explore["arm#{i}"]
        arms[i].add_count(((STEP_IMP*(1 - epsilon))*exploit_rate[i])/100 + ((STEP_IMP*epsilon)*explore_rate[i])/100)
      end
      exploit_rate = change_exploit_rate(exploit_rate, check_revenue(explore))
    end
    arms.each_with_object([]) do |a, arms_count|
      arms_count << a.count.to_i
    end
  end

  def ucb
    init_rate = [100, 0, 0, 0]
    exploit_rate  = init_rate
    exploit       = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
    h_result      = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
    arms          = Array.new
    ARM_NUM.times do |i|
      arms << Arm.new(INITIAL_CTR["arm#{i}"], CPC)
    end
    0.step(MAX_IMP, STEP_IMP) do |imp|
      #探索用レートの初期化
      ARM_NUM.times do |i|
        h_result["arm#{i}"] = arms[i].heuristic_ucb(imp)
      end
      exploit_rate = change_exploit_rate(exploit_rate, check_revenue(h_result))
      ARM_NUM.times do |i|
        #CTR変更
        arms[i].change_ctr((INITIAL_CTR["arm#{i}"] + tremor_ctr).round(1))
        #UCBは活用revenue のみ
        exploit["arm#{i}"] += arms[i].revenue((STEP_IMP*exploit_rate[i])/100)
        arms[i].add_count((STEP_IMP*exploit_rate[i])/100)
      end
    end
    arms.each_with_object([]) do |a, arms_count|
      arms_count << a.count
    end
  end

  private
  #CTRのゆらぎ
  def tremor_ctr
    (3 - rand(7)).to_f/10
  end
  def check_revenue(revenue)
    max = revenue.max { |(k1, v1), (k2, v2)| v1<=>v2 }
    max.first.gsub(/[^0-9]/,"").to_i
  end

  def change_exploit_rate(exploit_rate, max_arm)
    ARM_NUM.times do |i|
      exploit_rate[i] = ((i==max_arm) ? 100 : 0)
    end
    exploit_rate
  end
end

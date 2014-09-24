require './arm.rb'

#初期値
CPC         = 1.5
initial_ctr = { "arm0" => 0.7, "arm1" => 0.8, "arm2" => 0.6, "arm3" => 0.5 }
ARM_NUM     = 4
arms        = Array.new
tau         = 0.1
#CTRのゆらぎ
def tremor_ctr
  (3 - rand(7)).to_f/10
end

ARM_NUM.times do |i|
  arms << Arm.new(initial_ctr["arm#{i}"], CPC)
end

max_imp   = 10_000_000
step_imp  =    100_000
init_rate = [100, 0, 0, 0]
exploit_rate  = init_rate
exploit       = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
h_result      = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }

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

0.step(max_imp, step_imp) do |imp|
  #探索用レートの初期化
  ARM_NUM.times do |i|
    h_result["arm#{i}"] = arms[i].heuristic_ucb(imp)
  end
  exploit_rate = change_exploit_rate(exploit_rate, check_revenue(h_result))
  ARM_NUM.times do |i|
    #CTR変更
    arms[i].change_ctr((initial_ctr["arm#{i}"] + tremor_ctr).round(1))
    #UCBは活用revenue のみ
    exploit["arm#{i}"] += arms[i].revenue((step_imp*exploit_rate[i])/100)
    arms[i].add_count((step_imp*exploit_rate[i])/100)
  end
end
# revenue最大化
p exploit.values.inject(:+)

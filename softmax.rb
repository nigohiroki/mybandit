require './arm.rb'

#初期値
CPC         = 1.5
initial_ctr = { "arm0" => 0.7, "arm1" => 0.8, "arm2" => 0.6, "arm3" => 0.5 }
ARM_NUM     = 4
arms        = Array.new
tau         = 0.1
epsilon     = 0.1
#CTRのゆらぎ
def tremor_ctr
  (3 - rand(7)).to_f/10
end

ARM_NUM.times do |i|
  arms << Arm.new(initial_ctr["arm#{i}"], CPC)
end

max_imp   = 10_000_000
step_imp  =    100_000
init_rate = [25, 25, 25, 25]
exploit_rate  = init_rate
explore_rate  = init_rate
exploit       = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
explore       = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }
explore_total = { "arm0" => 0, "arm1" => 0, "arm2" => 0, "arm3" => 0 }

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
    explore_rate[i] = (arms[i].weighted_avg(arms, tau) * 100).round(1)
  end
  ARM_NUM.times do |i|
    #CTR変更
    arms[i].change_ctr((initial_ctr["arm#{i}"] + tremor_ctr).round(1))
    #活用revenue and 探索revenue
    exploit["arm#{i}"] += arms[i].revenue(((step_imp*(1 - epsilon))*exploit_rate[i])/100)
    explore["arm#{i}"]  = arms[i].revenue(((step_imp*epsilon)*explore_rate[i])/100)
    explore_total["arm#{i}"] += explore["arm#{i}"]
  end
  exploit_rate = change_exploit_rate(exploit_rate, check_revenue(explore))
end
# revenue最大化
p exploit.values.inject(:+) + explore_total.values.inject(:+)

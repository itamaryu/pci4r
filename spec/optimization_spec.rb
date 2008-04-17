require File.join(File.dirname(__FILE__), "../lib/optimization")

PEOPLE = [
  %w(Seymour BOS),
  %w(Franny DAL),
  %w(Zooey CAK),
  %w(Walt MIA),
  %w(Buddy ORD),
  %w(Les OMA)
]

def schedule_cost(solution, people, flights, dest)
  total_price = 0
  latest_arrival = 0
  earliest_dep = 24 * 60
  
  # first calculate latest_arrival and earliest_dep
  (0...solution.size / 2).each do |d|
    origin = people[d][1]
    outbound = flights[[origin, dest]][solution[d].to_i]
    return_flight = flights[[dest, origin]][solution[d + 1].to_i]

    total_price += outbound[2]
    total_price += return_flight[2]

    if latest_arrival < get_minutes(outbound[1])
      latest_arrival = get_minutes(outbound[1])
    end

    if earliest_dep > get_minutes(return_flight[0])
      earliest_dep = get_minutes(return_flight[0])
    end
  end

  # now loop again to calculate total_wait (which depends on
  # latest_arrival and earliest_dep)
  total_wait = 0
  (0...solution.size / 2).each do |d|
    origin = people[d][1]
    outbound = flights[[origin, dest]][solution[d].to_i]
    return_flight = flights[[dest, origin]][solution[d + 1].to_i]

    total_wait += latest_arrival - get_minutes(outbound[1])
    total_wait += get_minutes(return_flight[0]) - earliest_dep
  end
  
  if latest_arrival > earliest_dep
    total_price += 50
  end
  
  total_price + total_wait
end

def print_schedule(solution, people, flights, dest)
  out = ""
  (0...solution.size / 2).each do |d|
    name = people[d][0]
    origin = people[d][1]
    outbound = flights[[origin, dest]][solution[d]]
    ret = flights[[dest, origin]][solution[d + 1]]
    out << sprintf("%10s %10s %5s-%5s $%3s %5s-%5s $%3s\n",
           name,
           origin,
           outbound[0],
           outbound[1],
           outbound[2],
           ret[0],
           ret[1],
           ret[2])
  end
  out
end

def get_minutes(t)
  _, hrs, mins = t.to_s.match(/(\d+):(\d+)/)
  hrs.to_i * 60 + mins.to_i
end

##
# Extracts flights from the given CSV file and returns a
# <tt>Hash</tt>
def extract_flights(file)
  flights = {}
  open(file).each do |line|
    origin, dest, depart, arrive, price = line.strip.split(',')
    (flights[[origin, dest]] ||= []) << [depart, arrive, price.to_i]
  end
  flights
end

describe "Optimization" do
  before(:each) do
    file = File.join(File.dirname(__FILE__), "../data/schedule.txt")
    @flights = extract_flights(file)
    @dest = "LGA"
    @people = [
      %w(Seymour BOS),
      %w(Franny DAL),
      %w(Zooey CAK),
      %w(Walt MIA),
      %w(Buddy ORD),
      %w(Les OMA)
    ]
    @solution = [1, 4, 3, 2, 7, 3, 6, 3, 2, 4, 5, 3]
  end

  it "should random optimize correctly" do
    domain = [[0, 8]] * (@people.size * 2)
    s = Optimization.random_optimize(domain) do |r|
      schedule_cost(r, @people, @flights, @dest)
    end

    s.size.should == @people.size * 2
    sched = print_schedule(s, @people, @flights, @dest).split("\n")
    sched.size.should == @people.size
  end
end
INF = Float::INFINITY

class TSP
  attr_reader :tour, :min_tour_cost

  def initialize(start, distance)
    @n = distance.size
    raise 'Matrix harus n x n' unless @n == distance[0].size
    raise 'Matrix terlalu besar untuk n > 32' if @n > 32

    @start = start
    @distance = distance
    @memo = Array.new(@n) { Array.new(1 << @n) }
    @ran_solver = false
    @tour = []
    @min_tour_cost = INF
  end

  def solve
    return if @ran_solver
    end_state = (1 << @n) - 1

    @n.times do |end_node|
      next if end_node == @start
      @memo[end_node][(1 << @start) | (1 << end_node)] = @distance[@start][end_node]
    end

    (3..@n).each do |r|
      combinations(r, @n).each do |subset|
        next if not_in?(@start, subset)
        @n.times do |next_node|
          next if next_node == @start || not_in?(next_node, subset)

          subset_without_next = subset ^ (1 << next_node)
          min_dist = INF

          @n.times do |end_node|
            next if end_node == @start || end_node == next_node || not_in?(end_node, subset)

            prev_cost = @memo[end_node][subset_without_next]
            next if prev_cost.nil?

            new_dist = prev_cost + @distance[end_node][next_node]
            min_dist = [min_dist, new_dist].min
          end

          @memo[next_node][subset] = min_dist
        end
      end
    end

    @n.times do |i|
      next if i == @start
      cost = @memo[i][end_state]
      next if cost.nil?
      cost += @distance[i][@start]
      @min_tour_cost = [@min_tour_cost, cost].min
    end

    last_index = @start
    state = end_state
    @tour << @start

    (@n - 1).times do
      best_index = -1
      best_dist = INF

      @n.times do |j|
        next if j == @start || not_in?(j, state)
        prev_cost = @memo[j][state]
        next if prev_cost.nil?
        cost = prev_cost + @distance[j][last_index]
        if cost < best_dist
          best_dist = cost
          best_index = j
        end
      end

      @tour << best_index
      state ^= (1 << best_index)
      last_index = best_index
    end

    @tour << @start
    @tour.reverse!
    @ran_solver = true
  end

  private

  def not_in?(elem, subset)
    ((1 << elem) & subset).zero?
  end

  def combinations(r, n)
    result = []
    generate_combinations(0, 0, r, n, result)
    result
  end

  def generate_combinations(set, at, r, n, result)
    return if n - at < r
    if r == 0
      result << set
    else
      at.upto(n - 1) do |i|
        set |= (1 << i)
        generate_combinations(set, i + 1, r - 1, n, result)
        set &= ~(1 << i)
      end
    end
  end
end

if __FILE__ == $0
  print "Masukkan nama file input (contoh: input.txt): "
  filename = "input/" + gets.strip

  begin
    lines = File.readlines(filename).map(&:strip)
  rescue
    puts "Gagal membaca file '#{filename}'"
    exit
  end

  n = lines[0].to_i
  distance = Array.new(n) { Array.new(n, 10000) }

  lines[1..].each do |line|
    from, to, cost = line.split.map(&:to_i)
    distance[from][to] = cost
  end

  start = 0
  tsp = TSP.new(start, distance)
  tsp.solve

  puts "\nJumlah simpul: #{n}"
  puts "Edge input:"
  puts "From   to  cost"
  lines[1..].each do |line|
    from, to, cost = line.split.map(&:to_i)
    puts "  #{from} -> #{to} = #{cost}"
  end

  puts "\nTour: #{tsp.tour.inspect}"
  puts "Tour cost: #{tsp.min_tour_cost}"

  File.open("output/output.txt", "w") do |f|
    f.puts "Jumlah simpul: #{n}"
    f.puts "Edge input:"
    lines[1..].each do |line|
      from, to, cost = line.split.map(&:to_i)
      f.puts "  #{from} -> #{to} = #{cost}"
    end
    f.puts "\nTour: #{tsp.tour.inspect}"
    f.puts "Tour cost: #{tsp.min_tour_cost}"
  end
end

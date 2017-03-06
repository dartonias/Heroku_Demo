module WeightedClassifier
  class Bayes
    attr_accessor :unique

    def initialize(*args)
      @data = Hash.new
      @totals = Hash.new(0)
      @category_counts = Hash.new
      @total_trainings = 0
      args.each do |arg|
        @data[arg] = Hash.new(0)
        @category_counts[arg] = 0
      end
      # Some defaults that can be changed through accessors
      @unique = true
    end

    def train(category_array, text)
      if (category_array - @data.keys).empty?
        text_array = text.split()
        if @unique
          text_array = text_array.uniq
        end
        text_array.each do |t|
          category_array.each do |c|
            @data[c][t] ||= 0
            @data[c][t] += 1
          end
          @totals[t] ||= 0
          @totals[t] += 1
        end
        category_array.each do |c|
          @category_counts[c] += 1
        end
        @total_trainings += 1
      else
        raise "Category #{category_array - @data.keys} not in the set of categories"
      end
    end

    def classifications(text)
      text_array = text.split()
      if @unique
        text_array = text_array.uniq
      end
      results = {}
      @data.keys.each do |c|
        eta = 0
        text_array.each do |t|
          # Probability that we are in category c given we see word t, P(c|t)
          p_c = 0.5
          #p_c = @category_counts[c] / @total_trainings.to_f
          s = 3
          p_c_t = (s * p_c + @data[c][t])/(s + @totals[t])
          eta += Math.log(1.0 - p_c_t) - Math.log(p_c_t)
        end
        results[c] = 1.0/(1.0 + Math.exp(eta))
      end
      return results
    end
  end
end
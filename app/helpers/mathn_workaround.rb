module MathnWorkaround

  def self.intercept
    Fixnum.class_eval do
      alias regular_division /
    end
    yield
    Fixnum.class_eval do
      alias / regular_division
    end
  end

  def self.with_exact_division
    Fixnum.class_eval do
      alias / quo
    end
    yield
  ensure
    Fixnum.class_eval do
      alias / regular_division
    end
  end

end

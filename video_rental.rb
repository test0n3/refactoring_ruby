# frozen_string_literal: true

# class movie
class Movie
  REGULAR = 0
  NEW_RELEASE = 1
  CHILDRENS = 2

  attr_reader :title, :price_code

  def initialize(title, price_code)
    @title = title
    self.price_code = price_code
  end

  def price_code=(value)
    @price_code = value
    @price = case price_code
             when REGULAR
               RegularPrice.new
             when NEW_RELEASE
               NewReleasePrice.new
             when CHILDRENS
               ChildrensPrice.new
             end
  end

  def charge(days_rented)
    @price.charge(days_rented)
  end

  def frequent_renter_points(days_rented)
    @price.frequent_renter_points(days_rented)
  end
end

# module to share frequent_renter_points method
module DefaultPrice
  def frequent_renter_points(_days_rented)
    1
  end
end

# class for Regular type movies
class RegularPrice
  include DefaultPrice

  def charge(days_rented)
    if days_rented > 2
      2 + 1.5 * (days_rented - 2)
    else
      2
    end
  end
end

# class for NewRelease type movies
class NewReleasePrice
  def charge(days_rented)
    days_rented * 3
  end

  def frequent_renter_points(days_rented)
    days_rented > 1 ? 2 : 1
  end
end

# class for Children type movies
class ChildrensPrice
  include DefaultPrice

  def charge(days_rented)
    if days_rented > 3
      1.5 + 1.5 * (days_rented - 3)
    else
      1.5
    end
  end
end

# class rental
class Rental
  attr_reader :movie, :days_rented

  def initialize(movie, days_rented)
    @movie = movie
    @days_rented = days_rented
  end

  def charge
    @movie.charge(days_rented)
  end

  def frequent_renter_points
    @movie.frequent_renter_points(days_rented)
  end
end

# class customer
class Customer
  attr_reader :name, :rentals

  def initialize(name)
    @name = name
    @rentals = []
  end

  def add_rental(arg)
    @rentals << arg
  end

  def statement
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      # show figures for this rental
      result += "\t#{element.movie.title}\t#{element.charge}\n"
    end
    # add footer lines
    result += "Amount owed is #{total_charge}\n"
    result += "You earned #{total_frequent_renter_points} frequent renter points"
    result
  end

  def html_statement
    result = "<h1>Rental Record for <em>#{@name}</em></h1>\n<p><ul>\n"
    @rentals.each do |element|
      # show figures for this rental
      result += "<li>#{element.movie.title}: #{element.charge}</li>\n"
    end
    # add footer lines
    result += "</ul></p>\n<p>Amount owed is <em>#{total_charge}</em></p>\n"
    result += "<p>You earned <em>#{total_frequent_renter_points}</em> frequent renter points</p>"
    result
  end

  private

  def total_charge
    @rentals.inject(0) { |result, rental| result + rental.charge }
  end

  def total_frequent_renter_points
    @rentals.inject(0) { |result, rental| result + rental.frequent_renter_points }
  end
end

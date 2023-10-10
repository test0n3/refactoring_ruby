# frozen_string_literal: true

# description behind '_()':
# https://stackoverflow.com/questions/58128241/minitest-warning-deprecated-global-use-of-must-match-use-obj

require 'minitest'
require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require_relative 'video_rental'

describe Customer do
  subject { Customer.new('Smith') }
  let(:rent) do
    ->(movie, days) { subject.add_rental(Rental.new(movie, days)) }
  end
  # let(:regular_movie)   { Movie.new 'Regent', Movie::RegularPrice.new }
  let(:regular_movie)   { Movie.new 'Regent', Movie::REGULAR }
  # let(:new_movie)       { Movie.new 'Newton', Movie::NewReleasePrice.new }
  let(:new_movie)       { Movie.new 'Newton', Movie::NEW_RELEASE }
  # let(:childrens_movie) { Movie.new 'Chills', Movie::ChildrensPrice.new }
  let(:childrens_movie) { Movie.new 'Chills', Movie::CHILDRENS }

  it 'has a name' do
    _(subject.name).must_equal 'Smith'
  end

  it 'keeps a record of rentals' do
    rent[:movie1, 2]
    rent[:movie2, 7]

    _(subject.rentals.length).must_equal 2
    _(subject.rentals[0].movie).must_equal :movie1
    _(subject.rentals[1].movie).must_equal :movie2
  end

  describe '#statement' do
    it 'outputs a String' do
      _(subject.statement).must_be_instance_of String
    end

    it 'includes a header line with the customer’s name' do
      _(subject.statement).must_include 'Rental Record for Smith'
    end

    describe 'rental costs for 1 day' do
      before do
        rent[regular_movie, 1]
        rent[new_movie,     1]
        rent[childrens_movie, 1]
      end

      it 'includes movie title and fee for each rented movie' do
        _(subject.statement).must_match(/^\tRegent\t2$/)
        _(subject.statement).must_match(/^\tNewton\t3$/)
        _(subject.statement).must_match(/^\tChills\t1\.5$/)
      end

      it 'includes the total fee for all rentals' do
        _(subject.statement).must_include 'Amount owed is 6.5'
      end

      it 'includes frequent renter points earned' do
        _(subject.statement).must_include 'You earned 3 frequent renter points'
      end
    end

    describe 'frequent renter points' do
      it 'bonus point for each new release movie rented for 2 or more days' do
        rent[new_movie, 1]
        rent[new_movie, 2] # <-- bonus point
        rent[regular_movie, 3]
        _(subject.statement).must_include 'You earned 4 frequent renter points'
      end
    end

    describe 'regular movie, more than two days' do
      it 'costs 2 dollars plus 1.5 dollars for each additional day' do
        rent[regular_movie, 4]
        _(subject.statement).must_match(/^\tRegent\t#{2 + 1.5 * 2}$/)
      end
    end

    describe 'childrens movie, more than three days' do
      it 'costs 1.5 dollars plus 1.5 dollars for each additional day' do
        rent[childrens_movie, 6]
        _(subject.statement).must_match(/^\tChills\t#{1.5 + 1.5 * 3}$/)
      end
    end

    describe 'complete example with different numbers' do
      it 'prints the statement as expected' do
        #                          fee     points
        # =======================================
        rent[regular_movie, 2]   # 2       1
        rent[regular_movie, 3]   # 3.5     1
        rent[new_movie, 1]       # 3       1
        rent[new_movie, 3]       # 9       2
        rent[childrens_movie, 3] # 1.5     1
        rent[childrens_movie, 4] # 3       1
        # =======================================
        #              total:      22.0    7

        _(subject.statement).must_equal <<~STATEMENT
          Rental Record for Smith
          \tRegent\t2
          \tRegent\t3.5
          \tNewton\t3
          \tNewton\t9
          \tChills\t1.5
          \tChills\t3.0
          Amount owed is 22.0
          You earned 7 frequent renter points
        STATEMENT
          .chomp
      end
    end
  end

  describe '#html_statement' do
    before do
      #                          fee     points
      # =======================================
      rent[regular_movie,   1]  # 2       1 pts
      rent[regular_movie,   7]  # 9.5     1 pts
      rent[childrens_movie, 5]  # 4.5     1 pts
      rent[new_movie,       6]  # 18      2 pts
      # =======================================
      #              total:       34.0    5 pts
    end

    it 'returns html output' do
      _(subject.html_statement).must_match(%r{<h1>.*</h1>})
    end

    it 'prints the correct values formatted as HTML' do
      _(subject.html_statement).must_equal <<~HTML
        <h1>Rental Record for <em>Smith</em></h1>
        <p><ul>
        <li>Regent: 2</li>
        <li>Regent: 9.5</li>
        <li>Chills: 4.5</li>
        <li>Newton: 18</li>
        </ul></p>
        <p>Amount owed is <em>34.0</em></p>
        <p>You earned <em>5</em> frequent renter points</p>
      HTML
        .chomp
    end
  end
end

describe Rental do
  subject { Rental.new(:movie, 5) }

  it 'remembers a movie' do
    _(subject.movie).must_equal :movie
  end

  it 'remembers the number of days' do
    _(subject.days_rented).must_equal 5
  end
end

describe Movie do
  # let(:regular)     { Movie::RegularPrice.new }
  let(:regular)     { Movie::REGULAR }
  # let(:new_release) { Movie::NewReleasePrice.new }
  let(:new_release) { Movie::NEW_RELEASE }
  # let(:childrens)   { Movie::ChildrensPrice.new }
  let(:childrens)   { Movie::CHILDRENS }

  let(:regular_movie)   { Movie.new('Alien', regular) }
  let(:new_movie)       { Movie.new('Titanic', new_release) }
  let(:childrens_movie) { Movie.new('Moon', childrens) }

  let(:initial_price) do
    Class.new(BasicObject) do
      def charge(_)
        :initial_charge
      end

      def frequent_renter_points(_)
        :initial_points
      end
    end.new
  end

  let(:updated_price) do
    Class.new(BasicObject) do
      def charge(_)
        :updated_charge
      end

      def frequent_renter_points(_)
        :updated_points
      end
    end.new
  end

  let(:invalid_price) { Class.new(BasicObject).new }
  let(:wrong_args) do
    Class.new(BasicObject) do
      def charge; end
      def frequent_renter_points; end
    end.new
  end

  describe 'injected price object' do
    it 'must respond to charge with 1 argument' do
      _(proc { Movie.new('title', invalid_price).charge(2) })
        .must_raise NoMethodError

      # _(proc { Movie.new('title', wrong_args).charge(2) })
      #   .must_raise ArgumentError
    end

    it 'must respond to frequent_renter_points with 1 argument' do
      _(proc { Movie.new('title', invalid_price).frequent_renter_points(1) })
        .must_raise NoMethodError

      # _(proc { Movie.new('title', wrong_args).frequent_renter_points(1) })
      #   .must_raise ArgumentError
    end

    it 'is used to calculate the charge and the frequent renter points' do
      skip
      movie = Movie.new 'title', initial_price
      _(movie.charge(1)).must_equal :initial_charge
      _(movie.frequent_renter_points(1)).must_equal :initial_points
    end

    describe 'a regular movie' do
      it 'price logic' do
        skip
        (1..2).each do |days|
          _(regular_movie.charge(days)).must_equal 2
        end
        _(regular_movie.charge(3)).must_equal 3.5
        _(regular_movie.charge(4)).must_equal 5.0
      end

      it 'points' do
        skip
        days = rand(1..10)
        _(regular_movie.frequent_renter_points(days)).must_equal 1
      end
    end

    describe 'a new release' do
      it 'price logic' do
        skip
        days = rand(1..10)
        _(new_movie.charge(days)).must_equal(3 * days)
      end

      it 'points' do
        skip
        _(new_movie.frequent_renter_points(1)).must_equal 1
        _(new_movie.frequent_renter_points(2)).must_equal 2
      end
    end

    describe 'a children’s movie' do
      it 'price logic' do
        skip
        (1..3).each do |days|
          _(childrens_movie.charge(days)).must_equal 1.5
        end
        _(childrens_movie.charge(4)).must_equal 3.0
        _(childrens_movie.charge(5)).must_equal 4.5
      end

      it 'points' do
        skip
        days = rand(1..10)
        _(childrens_movie.frequent_renter_points(days)).must_equal 1
      end
    end
  end

  it 'has a title' do
    _((Movie.new 'Alien', regular).title).must_equal 'Alien'
    _((Movie.new 'Alien', regular).price_code).must_equal Movie::REGULAR
  end

  it 'allows setting the price' do
    skip
    movie = Movie.new 'Solaris', regular
    movie.price = updated_price
    _(movie.charge(1)).must_equal :updated_charge
  end

  it 'does not allow reading the price' do
    _(proc { regular_movie.price }).must_raise NoMethodError
  end

  it 'does not allow changing the title' do
    movie = Movie.new 'Alien', regular
    _(proc { movie.title = 'x' }).must_raise NoMethodError
  end
end

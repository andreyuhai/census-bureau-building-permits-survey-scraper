require 'mechanize'
require_relative '../lib/database'

class BuildingPermitsSurveyScraper
  attr_accessor :agent, :db, :table_name, :scrape_dev_name

  def initialize(**params)
    db_username = params.fetch(:db_username)
    db_password = params.fetch(:db_password)
    db_host = params.fetch(:db_host)
    db_name = params.fetch(:db_name)
    @scrape_dev_name = params.fetch(:scrape_dev_name)
    @table_name = params.fetch(:table_name)

    @db = Database.new(db_username, db_password, db_host, db_name)
    create_building_permits_survey_table(@table_name)
    @agent = Mechanize.new
  end

  # @param [Date] from_date - inclusive
  # @param [Date] to_date - inclusive
  def scrape_between_dates(from_date, to_date)
    series  = %w[valuation units]
    type    = ['current month', 'year to date']

    series.each do |s|
      type.each do |t|
        until from_date > to_date
          params = form_url(date: from_date, series: s, type: t)
          scrape(params)
          from_date = from_date.next_month
        end
      end
    end
  end

  def scrape_previous_month
    date = Date.now.prev_month
  end

  # @param [Hash] params
  # @return [Hash] - returns the same params with formed url added with key :url
  def form_url(**params)
    date = params.fetch(:date)
    s = params.fetch(:series).downcase
    t = params.fetch(:type).downcase

    month = date.strftime('%m')
    year = date.year

    series = {
      units: 'u',
      valuation: 'v'
    }
    type = {
      'current month': 'tb2',
      'year to date': 't2y'
    }

    url = "https://www.census.gov/construction/bps/txt/#{type[t.to_sym]}#{series[s.to_sym]}#{year}#{month}.txt"
    params[:url] = url
    params
  end

  # @param [String] table_name
  def create_building_permits_survey_table(table_name)
    params = {
      table_name: table_name,
      columns: {
        id: 'INT AUTO_INCREMENT',
        year: 'INT',
        month: 'INT',
        series: 'VARCHAR(255)',
        type: 'VARCHAR(255)',
        state: 'VARCHAR(255)',
        total: 'INT',
        '1_unit': 'INT',
        '2_units': 'INT',
        '3_and_4_units': 'INT',
        '5_or_more_units': 'INT',
        num_of_structures_with_5_or_more_units: 'INT',
        scrape_dev_name: 'VARCHAR(100)',
        data_source_url: 'VARCHAR(255)',
        created_at: 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
        updated_at: 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP'
      },
      primary_key: 'id'
    }

    @db.create_table(params)
  end

  def scrape(params)
    url = params.fetch(:url)
    response = @agent.get url
    parsed_response_body = Nokogiri::HTML(response.body)
    pre_tagged_text = parsed_response_body.xpath('//p').text

    lines = []
    pre_tagged_text.split("\n").each { |line| lines << line }
    state_lines = []
    lines.each { |line| state_lines << line.strip if line.match? /^\s{4}\w+/ }

    state_lines.each do |line|
      state_name = line.match(/^\D+/).to_s.strip
      numbers = line.scan(/\d+/)
      numbers << 'NULL' if numbers.count == 5
      insert_into_table(state_name, numbers, params)
    end
  end

  # @param [String] state_name
  # @param [Array] numbers - array consisting of the numbers from the scraped page
  # @param [Hash] params - containing :date, :series and :type
  def insert_into_table(state_name, numbers, params)
    query_params = {
      table_name: @table_name,
      query: {
        year: params.fetch(:date).year,
        month: params.fetch(:date).strftime('%m'),
        series: params.fetch(:series),
        type: params.fetch(:type),
        state: state_name,
        total: numbers[0],
        '1_unit': numbers[1],
        '2_units': numbers[2],
        '3_and_4_units': numbers[3],
        '5_or_more_units': numbers[4],
        num_of_structures_with_5_or_more_units: numbers[5],
        scrape_dev_name: @scrape_dev_name,
        data_source_url: params.fetch(:url)
      }
    }
    @db.insert_into_table(query_params)
  end

  # @param [String] pre_tagged_text
  # @return [Boolean] - returns boolean depending on whether the file is available or not
  def file_available?(pre_tagged_text)
    !pre_tagged_text.include? 'The file you selected is not yet available.'
  end
end

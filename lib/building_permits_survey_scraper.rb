require 'mechanize'
require_relative '../lib/database'

class BuildingPermitsSurveyScraper

  attr_accessor :agent, :db, :table_name

  def initialize(**params)
    db_username = params.fetch(:db_username)
    db_password = params.fetch(:db_password)
    db_host = params.fetch(:db_host)
    db_name = params.fetch(:db_name)

    @db = Database.new(db_username, db_password, db_host, db_name)
  end

  def create_table(table_name)

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

  end

end
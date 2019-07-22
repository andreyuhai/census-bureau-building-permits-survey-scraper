require_relative 'lib/building_permits_survey_scraper'

building_permits_survey_scraper = BuildingPermitsSurveyScraper.new(
  db_username:  'DB_USERNAME',
  db_password:  'DB_PASSWORD',
  db_host:      'DB_HOST',
  db_name:      'DB_NAME',
  table_name:   'building_permits_survey',
  scrape_dev_name: 'scrape_dev_name'
)

# from_date = Date.new(2004, 01)
# to_date = Date.new(2019, 05)
#
# # Scrapes all the entries from 2004 - 04 (inclusive) to 2019 - 05 (inclusive)
# building_permits_survey_scraper.scrape_between_dates(from_date, to_date)

building_permits_survey_scraper.scrape_previous_month

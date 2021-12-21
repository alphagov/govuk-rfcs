# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "activesupport"
  gem "mongoid", "7.3"
end

Mongoid.load!(File.join(File.dirname(__FILE__), 'config.yml'), :development)

class WorldLocationType
  include Mongoid::Document
  field :name, type: String
  has_many :world_locations
end

class WorldLocation
  include Mongoid::Document
  field :title, type: String
  field :slug, type: String
  belongs_to :world_location_type
  has_many :world_location_groups

  def id
    "https://www.gov.uk/api/world-locations/#{slug}"
  end

  def web_url
    "https://www.gov.uk/world/#{slug}"
  end

  def format
    world_location_type.name
  end

  def details
    { slug: slug }
  end

  def england_coronavirus_travel
    begin
      if self.class.name == "WorldLocation"
        CoronavirusTravel.find_by(world_location_id: self._id).details
      elsif self.class.name == "Location"
        CoronavirusTravel.find_by(location_id: self._id).details
      else
        {}
      end
    rescue
      {}
    end
  end

  def to_json(options={})
    super(only: :title, methods: [:id, :format, :web_url, :details, :england_coronavirus_travel])
  end
end

class LocationType < WorldLocationType
  has_many :locations
end

class Location < WorldLocation
  include Mongoid::Document
  belongs_to :location_type
  has_many :world_location_groups

  def format
    location_type.name
  end
end

class WorldLocationGroup
  include Mongoid::Document
  field :name, type: String
  belongs_to :world_location
  belongs_to :location
end

class CoronavirusTravel
  include Mongoid::Document
  field :rag_status, type: String
  field :next_rag_status, type: String
  field :next_rag_status_applies_at, type: DateTime
  field :status_out_of_date, type: Boolean
  belongs_to :world_location, optional: true
  belongs_to :location, optional: true

  def details
    hash = {}
    hash[:rag_status] = rag_status unless rag_status.blank?
    hash[:next_rag_status] = next_rag_status unless next_rag_status.blank?
    hash[:next_rag_status_applies_at] = next_rag_status_applies_at unless next_rag_status_applies_at.blank?
    hash[:status_out_of_date] = status_out_of_date unless status_out_of_date.blank?
    hash
  end
end

CoronavirusTravel.destroy_all
WorldLocationGroup.destroy_all
Location.destroy_all
WorldLocation.destroy_all
LocationType.destroy_all
WorldLocationType.destroy_all

country = WorldLocationType.create!(name: "World location")

spain = WorldLocation.create!(title: "Spain", slug: "spain", world_location_type: country)
cyprus = WorldLocation.create!(title: "Cyprus", slug: "cyprus", world_location_type: country)
turkey = WorldLocation.create!(title: "Turkey", slug: "turkey", world_location_type: country)
greece = WorldLocation.create!(title: "Greece", slug: "greece", world_location_type: country)
israel = WorldLocation.create!(title: "Israel", slug: "israel", world_location_type: country)

city = LocationType.create!(name: "City")
region = LocationType.create!(name: "Region")
island = LocationType.create!(name: "Island")

mallorca = Location.create!(title: "Mallorca", slug: "mallorca", location_type: island, world_location_type: country)
menorca = Location.create!(title: "Menorca", slug: "menorca", location_type: island, world_location_type: country)
ibiza = Location.create!(title: "Ibiza", slug: "ibiza", location_type: island, world_location_type: country)
formentera = Location.create!(title: "Formentera", slug: "formentera", location_type: island, world_location_type: country)
tenerife = Location.create!(title: "Tenerife", slug: "tenerife", location_type: island, world_location_type: country)
gran_canaria = Location.create!(title: "Gran Canaria", slug: "gran-canaria", location_type: island, world_location_type: country)
lanzarote = Location.create!(title: "Lanzarote", slug: "lanzarote", location_type: island, world_location_type: country)
fuerteventura = Location.create!(title: "Fuerteventura", slug: "fuerteventura", location_type: island, world_location_type: country)
la_palma = Location.create!(title: "La Palma", slug: "la-palma", location_type: island, world_location_type: country)
la_gomera = Location.create!(title: "La Gomera", slug: "la-gomera", location_type: island, world_location_type: country)
el_hierro = Location.create!(title: "El Hierro", slug: "el-hierro", location_type: island, world_location_type: country)
famagusta = Location.create!(title: "Famagusta", slug: "famagusta", location_type: region, world_location_type: country)
kyrenia = Location.create!(title: "Kyrenia", slug: "kyrenia", location_type: region, world_location_type: country)
nicosia = Location.create!(title: "Nicosia", slug: "nicosia", location_type: region, world_location_type: country)
larnaca = Location.create!(title: "Larnaca", slug: "larnaca", location_type: region, world_location_type: country)
limassol = Location.create!(title: "Limassol", slug: "limassol", location_type: region, world_location_type: country)
paphos = Location.create!(title: "Paphos", slug: "paphos", location_type: region, world_location_type: country)
jerusalem = Location.create!(title: "Jerusalem", slug: "jerusalem", location_type: city, world_location_type: country)

WorldLocationGroup.create!([
  { world_location: spain, location: mallorca, name: "Balearic Islands" },
  { world_location: spain, location: menorca, name: "Balearic Islands" },
  { world_location: spain, location: ibiza, name: "Balearic Islands" },
  { world_location: spain, location: formentera, name: "Balearic Islands" },
  { world_location: spain, location: tenerife, name: "Canary Islands" },
  { world_location: spain, location: gran_canaria, name: "Canary Islands" },
  { world_location: spain, location: lanzarote, name: "Canary Islands" },
  { world_location: spain, location: fuerteventura, name: "Canary Islands" },
  { world_location: spain, location: la_palma, name: "Canary Islands" },
  { world_location: spain, location: la_gomera, name: "Canary Islands" },
  { world_location: spain, location: el_hierro, name: "Canary Islands" },
  { world_location: cyprus, location: famagusta, name: "North Cyprus" },
  { world_location: cyprus, location: kyrenia, name: "North Cyprus" },
  { world_location: cyprus, location: nicosia, name: "South Cyprus" },
  { world_location: cyprus, location: larnaca, name: "South Cyprus" },
  { world_location: cyprus, location: limassol, name: "South Cyprus" },
  { world_location: cyprus, location: paphos, name: "South Cyprus" },
  { world_location: turkey, location: famagusta },
  { world_location: turkey, location: kyrenia },
  { world_location: greece, location: nicosia },
  { world_location: greece, location: larnaca },
  { world_location: greece, location: limassol },
  { world_location: greece, location: paphos },
  { world_location: israel, location: jerusalem },
])

CoronavirusTravel.create!([
  { rag_status: "Green", world_location: spain },
  { rag_status: "Red", location: mallorca },
])

WorldLocation.all.each do |world_location|
  File.write("rfc-000/api/#{world_location.slug}.json", world_location.to_json)
end

# frozen_string_literal: false
require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'action_view'
require 'json'
require 'erb'
require 'fileutils'

# require 'pry'

include ActionView::Helpers::DateHelper

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Atomic Google Calendar Timeline'.freeze
CLIENT_SECRETS_PATH = 'client_secret.json'.freeze
CALENDAR_CONF_PATH = 'calendars.json'.freeze
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             'atomic-google-calendar-timeline.yaml')
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY

calendar_ids = JSON.parse(File.read(CALENDAR_CONF_PATH))

def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
         'resulting code after authorization'
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

def hour_as_time(hour)
  if hour <= 12
    "#{hour}:00 AM"
  else
    "#{hour - 12}:00 PM"
  end
end

service = Google::Apis::CalendarV3::CalendarService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

events = []

calendar_ids.each do |calendar_id|
  calendar_name = service.get_calendar(calendar_id).summary

  response = service.list_events(calendar_id,
                                 single_events: true,
                                 order_by: 'startTime',
                                 time_min: (Date.today + 4).to_time.iso8601,
                                 time_max: (Date.today + 5).to_time.iso8601)

  response.items.each do |event|
    name = event.summary
    start_time = event.start.date_time || event.start.date
    stop_time = event.end.date_time || event.end.date

    next unless (stop_time.instance_of? DateTime) && \
                (start_time.instance_of? DateTime)

    duration = distance_of_time_in_words(stop_time.to_time -
                                         start_time.to_time)
    display_start_time = start_time.strftime('%l:%M %p').strip
    display_stop_time = stop_time.strftime('%l:%M %p').strip

    attendees = []
    organizer = ''

    event&.attendees&.each do |attendee|
      unless attendee.resource
        attendees << (attendee.display_name || attendee.email)
      end
      if attendee.organizer
        organizer = (attendee.display_name || attendee.email)
      end
    end

    events << { name: name,
                start_time: start_time,
                stop_time: stop_time,
                display_start_time: display_start_time,
                display_stop_time: display_stop_time,
                duration: duration,
                attendees: attendees,
                organizer: organizer,
                calendar: calendar_name }
  end
end

events.flatten!
events = events.sort_by { |event| event[:start_time] }
events = events.uniq do |event|
  "#{event[:start_time]} #{event[:name]}"
end

template = File.read('templates/timeline.html.erb')
renderer = ERB.new(template)
puts renderer.result(binding)

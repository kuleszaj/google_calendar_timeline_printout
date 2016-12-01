# Google Calendar Timeline Printout

A Ruby script designed to print out a timeline of upcoming events from multiple Google Calendars.

## Getting Started

- Tested with Ruby 2.3.3
- `bundle install --path=vendor/bundle`
- Can make use of `wkhtmltopdf`, if available, to automate display and printing.
  - Tested with `wkhtmltopdf` version 0.12.4 on OSX.
- You will need to create a [Google API Project](https://console.developers.google.com/apis/api/calendar) with an OAuth 2.0 client ID.
  - Download the provided credentials as JSON, and store in `client_secret.json`
- You will need to populate the `calendars.json` with a list of Google Calendar ID's

## Initial Run

- `bundle exec ruby timeline_printout.rb`
- You will be prompted, at the command line, to authorize the script (via OAuth 2.0), to access calendars that your user has access to.

## Usage

- To generate the HTML timeline: `bundle exec ruby timeline_printout.rb > timeline_printout.rb`
- To generate and open the HTML timeline with `wkhtmltopdf`: `./bin/timeline_printout`

## License

See [LICENSE](LICENSE) file.

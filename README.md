Jobs API Server
==============

[![Build Status](https://travis-ci.org/GSA-OCSIT/jobs_api.png)](https://travis-ci.org/GSA-OCSIT/jobs_api)

The unemployment rate has hovered around 8 percent since early 2012. So, not surprisingly, many people are hitting the web to search for jobs. Federal, state, and local government agencies are hiring and have thousands of job openings across the country.

## Current Version

You are reading documentation for Jobs API v2. Documentation for v1 is available [here](https://github.com/GSA-OCSIT/jobs_api/tree/v1).

## Access the Data

Use our [Jobs API](http://usasearch.howto.gov/developer/jobs.html) to tap into a list of current jobs openings with the government. Jobs are searchable by keyword, location, agency, schedule, or any combination of these.

## Contribute to the Code

The server code that runs our [Jobs API](http://usasearch.howto.gov/developer/jobs.html) is here on Github. If you're a Ruby developer, keep reading. Fork this repo to add features (such as additional datasets) or fix bugs.

### Ruby

You'll need [Ruby 1.9.3](http://www.ruby-lang.org/en/downloads/).

### Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

### ElasticSearch

We're using [ElasticSearch](http://www.elasticsearch.org/) (>= 0.90) for fulltext search. On a Mac, it's easy to install with [Homebrew](http://mxcl.github.com/homebrew/).

    $ brew install elasticsearch

Otherwise, follow the [instructions](http://www.elasticsearch.org/download/) to download and run it.

### Geonames

We use the United States location data from [Geonames.org](http://www.geonames.org) to help geocode the locations of each job position. By assigning latitude and longitude coordinates to each position location, we can sort job results based on proximity to the user's location, provided that information is sent in with the request.

Download and extract the 'US.txt' file from [the Geonames archive](http://download.geonames.org/export/dump/US.zip), and import it into ElasticSearch.

    bundle exec rake geonames:import[/path/to/US.txt]

The file contains goecoding information for many entities that we aren't interested in for the purpose of government jobs (e.g., canals, churches), so we pick out just what we need in order to keep the index small with this AWK script:

    awk -F $'\\t' '$8 ~ /PPL|ADM\d?|PRK|BLDG|AIR|INSM/' US.txt > filtered_US.txt

This includes populated places, administrative areas, parks, buildings, airports, and military bases.

### Seed jobs data

You can use the sample.xml file just to load a few jobs and see the system working.

    bundle exec rake jobs:import_usajobs_xml[doc/sample.xml]

The importer adds to or updates any existing entries, so you can run it multiple times if you have multiple XML files. You can also start over with an index if you want to erase what's there or load a different dataset:

    bundle exec rake jobs:recreate_index
    bundle exec rake geonames:recreate_index

### Production data

Federal agencies can request XML files from USAJobs as described in the SIF Guide at [https://schemas.usajobs.gov/](https://schemas.usajobs.gov).

### Running it

Fire up a server and try it all out.

    bundle exec rails s

<http://127.0.0.1:3000/search.json?query=nursing+jobs&organization_id=VATA&hl=1>

### Parameters

These parameters are accepted:

1. query
2. organization_id
3. hl [highlighting]
4. size
5. from
6. tags
7. lat_lon

Full documentation on the parameters is in our [Jobs API documentation](http://usasearch.howto.gov/developer/jobs.html#parameters).

### Results

* `id`: Job identifier.
* `position_title`: The brief title of the job.
* `organization_name`: The full name of the hiring organization.
* `minimum, maximum`: The remuneration range for this position.
* `rate_interval_code`: This two letter code specifies the frequency of payment, most usually yearly or hourly. The full list of possibilities is [here](https://schemas.usajobs.gov/Enumerations/CodeLists.xml), about halfway down the page.
* `start_date, end_date`: The application period for this position.
* `locations`: Note that a job opening can have multiple locations associated with it.
* `url`: The official listing for the job.

Sample results:

    [
      {
        "id": "usajobs:327358300",
        "position_title": "Student Nurse Technicians",
        "organization_name": "Veterans Affairs, Veterans Health Administration",
        "minimum": 27,
        "maximum": 34,
        "rate_interval_code": "PH",
        "start_date": "2012-12-29",
        "end_date": "2013-2-28",
        "locations": [
          "Odessa, TX",
          "Fairfax, VA",
          "San Angelo, TX",
          "Abilene, TX"
        ],
        "url": "https://www.usajobs.gov/GetJob/ViewDetails/327358300"
      },
      {
        "id": "usajobs:325054900",
        "position_title": "Physician (Surgical Critical Care)",
        "organization_name": "Veterans Affairs, Veterans Health Administration",
        "minimum": 100000,
        "maximum": 150000,
        "rate_interval_code": "PA",
        "start_date": "2012-12-29",
        "end_date": "2013-2-28",
        "locations": [
          "Charleston, SC"
        ],
        "url": "https://www.usajobs.gov/GetJob/ViewDetails/325054900"
      }
    ]

### Expiration

When a job opening's end application date has passed, it is automatically purged from the index and won't show up in search results.

### API Versioning

We support API versioning with JSON format. The current version is v2. You can specify a specific JSON API version like this:

    curl -H 'Accept: application/vnd.usagov.position_openings.v2' http://localhost:3000/search.json?query=jobs

### Tests

These require an [ElasticSearch](http://www.elasticsearch.org/) server to be running.

    bundle exec rake spec

### Code Coverage

We track test coverage of the codebase over time, to help identify areas where we could write better tests and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/index.html`.

Click around on the files that have < 100% coverage to see what lines weren't exercised.

## Terms of Use

By accessing this Jobs API server, you agree to our [Terms of Service](http://www.usa.gov/About/developer-resources/terms-of-service.shtml).

Feedback
--------

You can send feedback via [Github Issues](https://github.com/GSA-OCSIT/jobs_api/issues).

-----

[Loren Siebert](https://github.com/loren) and [contributors](http://github.com/GSA-OCSIT/jobs_api/contributors).

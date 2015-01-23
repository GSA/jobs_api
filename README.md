Jobs API Server
==============

[![Build Status](https://travis-ci.org/GSA/jobs_api.png)](https://travis-ci.org/GSA/jobs_api)
[![Coverage Status](https://coveralls.io/repos/GSA/jobs_api/badge.png?branch=master)](https://coveralls.io/r/GSA/jobs_api?branch=master)

The server code that runs the DigitalGov Search [Jobs API](http://search.digitalgov.gov/developer/jobs.html) is here on Github. If you're a Ruby developer, keep reading. Fork this repo to add features (such as additional datasets) or fix bugs.

The documentation on request parameters and response format is on the [API developer page](http://search.digitalgov.gov/developer/jobs.html). 
This README just covers software development of the API service itself.

### Ruby

This code is currently tested against [Ruby 2.1](http://www.ruby-lang.org/en/downloads/).

### Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

### Elasticsearch

We're using [Elasticsearch](http://www.elasticsearch.org/) (>= 1.4.0) for fulltext search. On a Mac, it's easy to install with [Homebrew](http://mxcl.github.com/homebrew/).

    $ brew install elasticsearch

Otherwise, follow the [instructions](http://www.elasticsearch.org/download/) to download and run it.

### Geonames

We use the United States location data from [Geonames.org](http://www.geonames.org) to help geocode the locations of each job position. By assigning latitude and longitude coordinates to each position location, we can sort job results based on proximity to the searcher's location, provided that information is sent in with the request.

The 'US.txt' file from [the Geonames archive](http://download.geonames.org/export/dump/US.zip) contains goecoding information for many entities that we aren't interested in for the purpose of government jobs (e.g., canals, churches), so we pick out just what we need in order to keep the index small with this AWK script:

    awk -F $'\\t' '$8 ~ /PPL|ADM\d?|PRK|BLDG|AIR|INSM/' US.txt > doc/filtered_US.txt

This includes populated places, administrative areas, parks, buildings, airports, and military bases.

You can download, unzip, and filter a more recent version of the file if you like, or you can import the one in this repo to get started:

    bundle exec rake geonames:import[doc/filtered_US.txt]
    
If you are running Elasticsearch with the default 1g JVM heap, this import process will be pretty slow. 
You may want to consider [allocating more memory](http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/heap-sizing.html) to Elasticsearch.

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

### Parameters and Results

Full documentation on the parameters and result format is in our [Jobs API documentation](http://search.digitalgov.gov/developer/jobs.html).

### Expiration

When a job opening's end application date has passed, it is automatically purged from the index and won't show up in search results.

### API Versioning

We support API versioning with JSON format. The current/default version is v3. You can specify a specific JSON API version like this:

    curl -H 'Accept: application/vnd.usagov.position_openings.v3' http://localhost:3000/search.json?query=jobs

### Tests

These require an [Elasticsearch](http://www.elasticsearch.org/) server to be running.

    bundle exec rake spec

### Code Coverage

We track test coverage of the codebase over time, to help identify areas where we could write better tests and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/index.html`.

Click around on the files that have less than 100% coverage to see what lines weren't exercised by the tests.

Feedback
--------

You can send feedback via [Github Issues](https://github.com/GSA/jobs_api/issues).

-----

[Loren Siebert](https://github.com/loren) and [contributors](http://github.com/GSA/jobs_api/contributors).

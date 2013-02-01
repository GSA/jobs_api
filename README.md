Federal Jobs API Server
==============

## Purpose

The Federal Jobs API Server provides access to searchable job openings across the federal government. It includes all current job openings posted on [USAJobs.gov](http://www.usajobs.gov) that are open to the public and located in the United States.

You can see how this data is used when searching for jobs on federal websites that use USASearch ([TSA.gov](http://search.usa.gov/search?affiliate=tsa.gov&query=jobs), [USDA.gov](http://usdasearch.usda.gov/search?affiliate=usda&query=jobs), and [USA.gov](http://search.usa.gov/search?affiliate=usagov&query=jobs), for example).

## Ruby

You will need [Ruby 1.9.3](http://www.ruby-lang.org/en/downloads/).

## Gems

We use bundler to manage gems. You can install bundler and other required gems like this:

    gem install bundler
    bundle install

## ElasticSearch

We're using [ElasticSearch](http://www.elasticsearch.org/) for fulltext search.
On a Mac, it's easy to install with [http://mxcl.github.com/homebrew/](Homebrew):

    $ brew install elasticsearch

Otherwise, follow the instructions to download and run it [here](http://www.elasticsearch.org/download/).

Once it's running, create the index:

    bundle exec rake jobs:position_openings:recreate_index

# Seed data

Agencies can request XML files from USAJobs as described in the SIF Guide at [https://schemas.usajobs.gov/](https://schemas.usajobs.gov). If you don't have an official XML file from USAJobs, you can use the sample.xml file just to see it working with a few jobs:

    bundle exec rake jobs:position_openings:import_xml[doc/sample.xml]

The importer adds to or updates any existing entries, so you can run it multiple times if you have multiple XML files.

# Running it

Fire up a server and try it all out:

    bundle exec rails s

<http://127.0.0.1:3000/api/position_openings/search.json?query=nursing+jobs&organization_id=VATA&hl=1>

## Query

The query parameter is fairly flexible and attempts to extract as much "signal" as possible from the input text.
The search index handles variants of words, so a search on "nursing jobs" will find a job titled "nurse practitioner".
When parts of the query parameter are used to search against the position title, the results are ordered by relevance.
When no query parameter is specified, they are ordered by most recent first.

Here are some examples of query formats that will work:

### All jobs (most recent first)

* jobs
* positions
* vacancies
* opportunities
* postings

### Location-based (most recent first)

* jobs in fulton
* jobs in fulton, md
* jobs in fulton, maryland
* jobs in md

### Agency-based (most recent first)

* job opportunities at the cia
* jobs at the treasury dept
* tsa job openings
* va jobs # will match jobs in Virginia

### Job-based (by relevance)

* nursing jobs
* summer internship position

### Schedule-based (most recent first)

* part-time jobs
* full-time positions

### Combinations

* part-time security guard job openings at the tsa in los angeles, ca

## Organization ID (optional)

This is a two or four letter organization code specifying which federal agency to use as a filter, based on
[USAJobs' agency schema](https://schemas.usajobs.gov/Enumerations/AgencySubElement.xml). Two letter codes are used to span entire
departments, while four letter codes are generally used for independent agencies or agencies within a department.

Note that if you specify an organization ID in the API call but the user's query specifies another one, the user's
query will be used instead of the organization_id parameter. Example where we specify a filter for Air Force jobs,
but we type in a query searching for jobs at the VA. We show the VA jobs:

<http://127.0.0.1:3000/api/position_openings/search.json?query=jobs+at+the+va&organization_id=AF>

## Highlighting

You can pass the 'hl=1' setting to highlight terms in the position title that match terms in the user's query.
Highlighted terms are surrounded with &lt;em&gt; tags. The default is no highlighting.

## Size / From

You can specify how many results are returned (up to 100 at a time) with the size parameter, and you can choose a starting
record with the 'from' parameter.

## Results

* `id`: Job identifier. You can see the current official listing for job XYZ at https://www.usajobs.gov/GetJob/ViewDetails/XYZ.
* `position_title`: The brief title of the job.
* `organization_name`: The full name of the hiring organization.
* `minimum, maximum`: The remuneration range for this position.
* `rate_interval_code`: This two letter code specifies the frequency of payment, most usually yearly or hourly. The full list of possibilities is [here](https://schemas.usajobs.gov/Enumerations/CodeLists.xml), about halfway down the page.
* `start_date, end_date`: The application period for this position.
* `locations`: Note that a job opening can have multiple locations associated with it.

Sample results:

    [
      {
        "id": "327358300",
        "position_title": "Student Nurse Technicians",
        "organization_name": "Veterans Affairs, Veterans Health Administration",
        "minimum": "27",
        "maximum": "34",
        "rate_interval_code": "PH",
        "start_date": "2012-12-29",
        "end_date": "2013-2-28",
        "locations": [
          "Odessa, TX",
          "Fairfax, VA",
          "San Angelo, TX",
          "Abilene, TX"
        ]
      },
      {
        "id": "325054900",
        "position_title": "Physician (Surgical Critical Care)",
        "organization_name": "Veterans Affairs, Veterans Health Administration",
        "minimum": "100000",
        "maximum": "150000",
        "rate_interval_code": "PA",
        "start_date": "2012-12-29",
        "end_date": "2013-2-28",
        "locations": [
          "Charleston, SC"
        ]
      }
    ]

You can use browser extensions to view nicely formatted JSON data.

For Chrome: <https://chrome.google.com/webstore/search/json?hl=en-US>

For Firefox: <https://addons.mozilla.org/en-US/firefox/search/?q=json>

## Expiration

When a job opening's end application date has passed, it is automatically purged from the index and won't show up in search results.

# API Versioning

We support API versioning with JSON format. The current version is v1.

You can specify a specific JSON API version like this:

    curl -H 'Accept: application/vnd.usagov.position_openings.v1' http://localhost:3000/api/position_openings/search.json?query=jobs

# Tests

These require an [ElasticSearch](http://www.elasticsearch.org/) server to be running.

    bundle exec rake spec

# Code Coverage

We track test coverage of the codebase over time, to help identify areas where we could write better tests and to see when poorly tested code got introduced.

After running your tests, view the report by opening `coverage/index.html` in your favorite browser.

You can click around on the files that have < 100% coverage to see what lines weren't exercised.

Feedback
--------

You can send feedback via [Github Issues](https://github.com/GSA-OCSIT/jobs_api/issues).

-----

[Loren Siebert](https://github.com/loren) and [contributors](http://github.com/GSA-OCSIT/jobs_api/contributors).

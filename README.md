
# Sample Lumen App

This is a sample application running the
[Lumen](https://github.com/codeforkjeff/lumen) discovery
platform. It's a starting point for getting a test app running and
playing with customization.

Eventually this will be replaced with some way to generate new
skeletal Lumen applications, using sbt template, giter8, activator, or
something else.

# Installation

## Clone Repositories

You'll need this one, and `lumen` too. They need to live in the same
directory.

```
# in these examples, we clone into our home directory
cd ~
git clone git@github.com:codeforkjeff/lumen.git
git clone git@github.com:codeforkjeff/lumen-sample-app.git
```

## Configure Solr

If you aren't already running Solr 6.x somewhere, download it.

Lumen's default configuration expects a Solr core named
"lumen-core". You can use the config files in the `solr/` directory,
which is just a copy of the Solr config that Blacklight ships with.

```
mkdir /opt/solr/server/solr/lumen-core
cp -rp ~/lumen-sample-app/solr/conf /opt/solr/server/solr/lumen-core
```

Restart Solr. Then you should be able to add the core to Solr using
the web interface at http://localhost:8983/solr

## Index Some Records

The `indexing/` directory contains a Ruby script derived from
Blacklight that can index into the core set up above. You can use your
own marc records, or download some freely available records from
archive.org.

```
cd ~/lumen-sample-app/indexing

# install ruby gems
bundle install --path vendor/bundle

# this file is ~218M and contains ~245,000 records
wget https://archive.org/download/marc_ithaca_college/ic_marc.mrc

# optional: if appropriate, point to some other Solr instance
export SOLR_URL=http://somehost:8983/solr/lumen-core

# index records
bundle exec ruby index.rb ic_marc.mrc
```

## Run the Application in Development Mode

Install [Scala 2.11.8](https://www.scala-lang.org/download/) and [sbt](http://www.scala-sbt.org/). Type:

```
cd ~/lumen-sample-app
sbt run
```

Start using the app at http://localhost:9000/catalog

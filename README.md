![Scumblr](http://i.imgur.com/iFgqbrB.png)
# Scumblr

## What is Scumblr?

Scumblr is a web application that allows performing periodic searches and storing / taking actions on the identified results. Scumblr uses the [Workflowable gem](https://github.com/Netflix/Workflowable) to allow setting up flexible workflows for different types of results.

## How do I use Scumblr?

Scumblr is a web application based on Ruby on Rails. In order to get started, you'll need to setup / deploy a Scumblr environment and configure it to search for things you care about. You'll optionally want to setup and configure workflows so that you can track the status of identified results through your triage process.

## What can Scumblr look for?

Just about anything! Scumblr searches utilize plugins called *Search Providers*. Each Search Provider knows how to perform a search via a certain site or API (Google, Bing, eBay, Pastebin, Twitter, etc.). Searches can be configured from within Scumblr based on the options available by the Search Provider. What are some things you might want to look for? How about:

* Compromised credentials
* Vulnerability / hacking discussion
* Attack discussion
* Security relevant social media discussion
* ...

These are just a few examples of things that you may want to keep an eye on!

# Scumblr found stuff, now what?

Up to you! You can create simple or complex workflows to be used along with your results. This can be as simple as marking results as "Reviewed" once they've been looked at, or much more complex involving multiple steps with automated actions occurring during the process.

# Sounds great! How do I get started?

Take a look at the [wiki](https://github.com/Netflix/Scumblr/wiki) for detailed instructions on setup, configuration, and use!


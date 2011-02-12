#Ursa

Ursa is a simple blogaware static site generator written in ruby, using tilt for layouts and maruku for markdown.
The code is minimal, ppl can change it to suite their own tastes.

### Installation
download the git repo and execute.

	chmod +x ursa

the executable should be accessible when it is run in a new directory with the following directory structure.


### Directory Structure
The directories ursa needs to run by are given below, these directories need to present in the directory in which ursa is executed. all these default directories can be changed through \_config.yml

	_posts #for posts or pages in markdown
	_tags #for partials in haml
	_layouts #for templates in haml
	css #for css and sass files

### YAML front matter
each post must start with yaml front matter of the format

	---
	title: first blog post #title is compulsory
	layout: post
	date: 2011-02-11
	author: mrphoebs #default author an be set through config
	type: blogpost
	categories: trivial, sample
	---

the post attributes that can be set with yaml front matter are
	
	:title, :date, :layout, :categories, :type, :author

### layouts
layouts are haml templates placed in the layouts directory that have access to the following objects

	post, posts, config, categories

### partials
partials are haml fragments in the partials directory, partials are called from layouts using the following syntax

	= tag :partial_name,{:par1=>1,:par2=>2}

### \_config.yml
a \_config.yml file in the root directory where ursa is executed from is used to set configuration. see lib/config.rb for possible configuration options. \_config.yml should represent a hash.
additional global configuration options can be set here as well and they will be available to all the layouts.

### css
css directory will hold any css and sass files, running ursa will automatically generate css files from sass files.

### site
*site* is the default directory which will act as document root for the generated static page site.

### Atom feed
when ursa is run for the first time it creates an atom.haml template in the ursa execution directory, modify this template and fill with appropriate values, from the next iteration this template will be used
to generate an atom.xml file in the site root.

### Organization
use site as your static root directory, css, images and js will be one directory above root directory

require 'rubygems'
require 'yaml'
require 'haml'
require 'tilt'
require 'maruku'
require 'fileutils'
require File.join('lib','config')

class Post

	attr_accessor :title, :date, :layout, :categories, :content, :type, :author, :site_title, :file

end

module Ursa

ATOM_TEMPLATE = <<EOH
<?xml version="1.0" encoding="utf-8"?>
%feed{:xmlns=>"http://www.w3.org/2005/Atom"}
  %title~ site_title
  %subtitle~ "***site subtitile***"
  %link{:href=>"***site_url/atom.xml***",:rel=>"self"}
  %link{:href=>"***site_url***"}
  %id~ "***siteurl/uniqueid***"
  %updated~ atom_time
  %author
    %name~ "***site author name***"
    %email~ "***site author email***"
  
  - posts[0...10].each do |post|
    %entry
      %title~ post.title
      %link{:href=>"***site url***"+post.file}
      %id~ "***site url***"+post.file
      %updated~ atom_date(post.date)
      %content{:type=>"html"}
        post.content
EOH


	POSTS = Array.new

	CATEGORIES = Hash.new

	def sort_posts
		Ursa::POSTS.sort!{|a,b| b.date<=>a.date}
	end
	
	def yaml_front_matter(post_text)
		begin
			front_matter = post_text.split(/---\n/)[1]
			yaml_matter = YAML::load(front_matter)
			yaml_matter
		rescue
			"YAML front matter exception"
		end	
	end

	def get_markdown(post_text)
		puts post_text
		markdown = post_text.split(/---\n/)[2...10000].join("")
		markdown
	end

	def get_post_text(post)
		if($CURRENT_DIR!=nil && File.exists?(File.join($CURRENT_DIR,"#{Ursa::CONFIG["postsdir"]}",post+".#{Ursa::CONFIG["markdown_extension"]}")))
			post_file = File.open(File.join($CURRENT_DIR,"#{Ursa::CONFIG["postsdir"]}",post+".#{Ursa::CONFIG["markdown_extension"]}"),"r")
			post_text = post_file.read
			post_file.close
			post_text
		end
	end

	
	def to_html(markdown_string)
		Maruku.new(markdown_string).to_html
	end

	def get_post(post)
		post_text = get_post_text(post)
		yaml_matter = yaml_front_matter(post_text)
		markdown = get_markdown(post_text)
		html_content = to_html(markdown)
		post = Post.new
		post.title = yaml_matter["title"]
		post.file = post.title.gsub(/\W/,"_")+".html"
		if yaml_matter["type"]==nil
			post.type="#{Ursa::CONFIG["default_post_type"]}"
		else
			post.type=yaml_matter["type"]
		end

		if yaml_matter["author"]==nil
			post.author="#{Ursa::CONFIG["author"]}"
		else
			post.author = yaml_matter["author"]
		end		

		if yaml_matter["date"]==nil
			post.date = Date.today
		else
			post.date = yaml_matter["date"]
		end

		if yaml_matter["layout"]==nil
			post.layout = "#{Ursa::CONFIG["default_layout"]}"
		else
			post.layout = yaml_matter["layout"]
		end
		if yaml_matter["categories"]==nil
			post.categories = Array.new
		else
			post.categories = yaml_matter["categories"]
		end
		post.content = html_content
		post
	end

	def load_config
		if(File.exists?(File.join($CURRENT_DIR,"_config.yml")))
			begin
				config = YAML::load_file(File.join($CURRENT_DIR,"_config.yml"))
				raise "Invalid configuration file, its not a hash" if !config.is_a?(Hash)
			rescue => err
				puts err.to_s
				config = {}
			end
			Ursa::CONFIG.merge!(config)
		end
	end

	def compile_sass
		if(File.directory?(File.join($CURRENT_DIR,"#{Ursa::CONFIG["cssdir"]}")))
			sass_files = Dir.glob(File.join($CURRENT_DIR,"#{Ursa::CONFIG["cssdir"]}/*.sass"))

			sass_files.each do |sass_file|
				template = Tilt.new(sass_file)
				css_content = template.render
				css_file = File.open(sass_file.sub(/\.sass/,".css"),"w");
				css_file.write css_content
				css_file.close
			end
		end
	end

	def load_posts
		if(File.directory?(File.join($CURRENT_DIR,"#{Ursa::CONFIG["postsdir"]}")))
			files = Dir.glob(File.join($CURRENT_DIR,"#{Ursa::CONFIG["postsdir"]}/*.#{Ursa::CONFIG["markdown_extension"]}"))
			files.map!{|file_path| file_path.split("/").last.split(".").first}
			
			files.each do |file|
				post = get_post(file)
				Ursa::POSTS << post
				post.categories.each do |category|
					if(Ursa::CATEGORIES[category]==nil)
						Ursa::CATEGORIES[category] = Array.new
						Ursa::CATEGORIES[category] << post
					else
						Ursa::CATEGORIES[category] << post
					end
				end				
			end
			sort_posts
		else
			puts "Error: no directory _posts found in the working directory"
			puts File.join($CURRENT_DIR,"#{Ursa::CONFIG["postsdir"]}")
		end
	end

	def render_posts
		if(!File.directory?(File.join($CURRENT_DIR,"#{Ursa::CONFIG["sitedir"]}")))
			Dir.mkdir(File.join($CURRENT_DIR,"#{Ursa::CONFIG["sitedir"]}"))
		else
			FileUtils.rm_rf(File.join($CURRENT_DIR,"#{Ursa::CONFIG["sitedir"]}"))
			Dir.mkdir(File.join($CURRENT_DIR,"#{Ursa::CONFIG["sitedir"]}"))
		end

		Ursa::POSTS.each do |post|
			if(File.exists?(File.join($CURRENT_DIR,"_layouts",post.layout+".haml")))
				template = Tilt.new((File.join($CURRENT_DIR,"_layouts",post.layout+".haml")))
				final_page_content = template.render(Object.new,:post=>post,:posts=>Ursa::POSTS,:categories=>Ursa::CATEGORIES,:config=>Ursa::CONFIG)
				file_name = post.file
 				static_file = File.open(File.join($CURRENT_DIR,"#{Ursa::CONFIG["sitedir"]}",file_name),"w")
				static_file.write final_page_content
				static_file.close
			else
				puts "Error no layout " + post.layout
			end
		end
	end

	def create_feed
		if(!File.exists?(File.join($CURRENT_DIR,"atom.haml")))
			atom_haml_file = File.open(File.join($CURRENT_DIR,"atom.haml"),"w")
			atom_haml_file.write Ursa::ATOM_TEMPLATE
			atom_haml_file.close 
		end
		template = Tilt.new(File.join($CURRENT_DIR,"atom.haml"))
		atom_content = template.render(Object.new,:posts=>Ursa::POSTS,:categories=>Ursa::CATEGORIES,:config=>Ursa::CONFIG)
		static_file = File.open(File.join($CURRENT_DIR,"#{Ursa::CONFIG["sitedir"]}","atom.xml"),"w")
		static_file.write atom_content
		static_file.close
	end

#----------------------------------------------------------------------template helpers start from here---------------------

	def tag(partial,map={})
		if($CURRENT_DIR!=nil && File.exists?(File.join($CURRENT_DIR,"#{Ursa::CONFIG["partialsdir"]}",partial.to_s+".#{Ursa::CONFIG["layout_extension"]}")))
			template = Tilt.new(File.join($CURRENT_DIR,"#{Ursa::CONFIG["partialsdir"]}",partial.to_s+".#{Ursa::CONFIG["layout_extension"]}"))
			template.render(Object.new,:map=>map)
		end
	end

	def css(path)
		"<link rel=\"stylesheet\" type=\"text/css\" href=\"#{path}\">"
	end

	def js(path)
		"<script type=\"text/javascript\" src=\"#{path}\"></script>"	
	end

	def site_title
		Ursa::CONFIG["site_title"]
	end

	def atom_link
		"<link href=\"atom.xml\" type=\"application/atom+xml\" rel=\"alternate\" title=\"#{site_title}\" />"
	end

	def atom_time
		t = Time.now
		str = t.strftime("%Y-%m-%d")+"T"+t.strftime("%T")+"Z"
		str
	end

	def atom_date(t)
		str = t.strftime("%Y-%m-%d")+"T00:00:00Z"
		str
	end
end

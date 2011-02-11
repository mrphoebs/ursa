require 'rubygems'
require 'yaml'
require 'haml'
require 'tilt'
require 'maruku'
require 'fileutils'

class Post

	attr_accessor :title, :date, :layout, :categories, :content, :type

end


module Ursa

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
		markdown = post_text.split(/---\n/)[2...1000].join("")
		markdown
	end

	def get_post_text(post)
		if($CURRENT_DIR!=nil && File.exists?(File.join($CURRENT_DIR,'_posts',post+".markdown")))
			post_file = File.open(File.join($CURRENT_DIR,'_posts',post+".markdown"),"r")
			post_text = post_file.read
			post_file.close
			post_text
		end
	end

	def include(partial,map={})
		if($CURRENT_DIR!=nil && File.exists?(File.join($CURRENT_DIR,'_includes',partials+".haml")))
			template = Tilt.new(File.join($CURRENT_DIR,'_includes',partial+".haml"))
			template.render(Object.new,:map=>map)
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
		if yaml_matter["type"]==nil
			post.type="blogpost"
		end

		if yaml_matter["date"]==nil
			post.date = Date.today
		else
			post.date = yaml_matter["date"]
		end

		if yaml_matter["layout"]==nil
			post.layout = "post"
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

	def load_posts
		if(File.directory?(File.join($CURRENT_DIR,"_posts")))
			files = Dir.glob(File.join($CURRENT_DIR,"_posts/*.markdown"))
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
		end
	end

	def render_posts
		if(!File.directory?(File.join($CURRENT_DIR,"site")))
			Dir.mkdir(File.join($CURRENT_DIR,"site"))
		else
			FileUtils.rm_rf(File.join($CURRENT_DIR,"site"))
			Dir.mkdir(File.join($CURRENT_DIR,"site"))
		end

		Ursa::POSTS.each do |post|
			if(File.exists?(File.join($CURRENT_DIR,"_layouts",post.layout+".haml")))
				template = Tilt.new((File.join($CURRENT_DIR,"_layouts",post.layout+".haml")))
				final_page_content = template.render(Object.new,:post=>post,:posts=>Ursa::POSTS,:categories=>Ursa::CATEGORIES)
				file_name = post.title.gsub(/\W/,"_")+".html"
				static_file = File.open(File.join($CURRENT_DIR,"site",file_name),"w")
				static_file.write final_page_content
				static_file.close
			else
				puts "Error no layout " + post.layout
			end
		end
	end

end

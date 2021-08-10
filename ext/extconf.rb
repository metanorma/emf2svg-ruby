$: << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require "emf2svg/recipe"

recipe = Emf2svg::Recipe.new
recipe.cook

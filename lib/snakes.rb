# frozen_string_literal: true
require 'curses'
require_relative "snakes/version"

module Snakes
  class Error < StandardError; end

  class Game
    def initialize()

      self.draw_board
    end 

    def draw_board
 
    end
  end
end

Snakes::Game.new.draw
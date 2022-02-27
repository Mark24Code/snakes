#!/usr/bin/env ruby

require "curses"

Curses.init_screen
Curses.cbreak
Curses.noecho
Curses.curs_set(0)  # Invisible cursor
Curses.stdscr.keypad = true

trap "INT" do
  SnakeGame.stop

  puts "Good Bye! :D"
  exit 130
end

class SnakeGame
  def initialize
    @fps = 40.0
    @refresh_time = 1 / @fps

    @frame = nil
    @board = nil

    @window_width = nil
    @window_height = nil

    @board_width = nil
    @board_height = nil

    @pause = false

    @direction = [:UP, :DOWN, :LEFT, :RIGHT]
    @current_direction = @direction.sample

    self.init_game_board

    @snake = (1..5).map { |i| [(@board_height / 2).to_i + i, (@board_width / 2).to_i] }

    @food = [@board_height / 2 + 2, @board_width / 2 + 2]

    @press = nil
    @score = 0
    @speed = 1
  end

  def init_game_board

    # Window Frame
    @window_height = Curses.lines
    @window_width = Curses.cols

    @board_height = (@window_height * 0.8).to_i
    @board_width = (@window_width * 0.6).to_i

    @info_board_height = (@window_height * 0.5).to_i
    @info_board_width = (@window_width * 0.3).to_i

    @frame = Curses::Window.new(@window_height, @window_width, 0, 0)

    title = "Snakes"
    @frame.setpos(0, @board_width / 2 - title.length / 2)
    @frame.addstr(title)
    @frame.refresh

    @board = @frame.subwin(
      @board_height,
      @board_width,
      1,
      1
    )
    @board.keypad = true
    @board.timeout = 500

    @board.box(0, 0)
    @board.refresh

    @info_board = @frame.subwin(
      @info_board_height,
      @info_board_width,
      1,
      @board_width + 1
    )
    @info_board.box(0, 0)
    @info_board.refresh
  end

  def create_food
    @food = [rand(1..@board_height - 1), rand(1..@board_width - 1)]

    unless is_safe_food?
      @food = [rand(1..@board_height - 1), rand(1..@board_width - 1)]
    end
  end

  def is_safe_food?
    return !@snake.include?(@food)
  end

  def render_game_info
    # Press Key
    @info_board.setpos(1, 1)
    @info_board.addstr("[Press]: #{@current_direction.to_s}")

    # score
    @info_board.setpos(3, 1)
    @info_board.addstr("[Score]: #{@score}")
  end

  def render_food
    food_y, food_x = @food
    @board.setpos(food_y, food_x)
    @board.addch("+")
  end

  def render_snake
    snake_path = @snake.dup

    head_y, head_x = snake_path.shift

    @board.setpos(head_y, head_x)
    @board.addch("*")

    snake_path.each do |node_pos|
      node_y, node_x = node_pos
      @board.setpos(node_y, node_x)
      @board.addstr("#")
    end
  end

  def add_step
    head_y, head_x = @snake.first.dup

    if @current_direction == :UP
      head_y -= 1
      if head_y <= 0
        head_y = 1
      end
    elsif @current_direction == :DOWN
      head_y += 1
      if head_y >= @board_height
        head_y = @board_height - 1
      end
    elsif @current_direction == :LEFT
      head_x -= 1
      if head_x <= 0
        head_x = 1
      end
    elsif @current_direction == :RIGHT
      head_x += 1
      if head_x >= @board_width
        head_x = @board_width - 1
      end
    else
      return
    end

    @snake.unshift([head_y, head_x])
    @snake.pop
    sleep 0.2
  end

  def _event_listener
    while true
      c = @board.getch
      if c
        @press = c
      end

      head_y, head_x = @snake.first.dup

      if c == Curses::KEY_UP || c == "w"
        @current_direction = :UP
      elsif c == Curses::KEY_DOWN || c == "s"
        @current_direction = :DOWN
      elsif c == Curses::KEY_LEFT || c == "a"
        @current_direction = :LEFT
      elsif c == Curses::KEY_RIGHT || c == "d"
        @current_direction = :RIGHT
      elsif c == Curses::KEY_BACKSPACE
        @pause = true
      else
        return
      end
    end
  end

  def main_loop
    loop do
      self._event_listener # 会维持在这里所以必须是最前面，尤其是要比clear 领先

      @board.clear
      @info_board.clear
      @board.box(0, 0)
      @info_board.box(0, 0)
      
      self.add_step
      self.render_snake
      self.render_food
      self.render_game_info

      @board.refresh
      @info_board.refresh
      sleep @refresh_time
    end
  end

  def run
    self.main_loop
  end

  class << self
    def run
      @app = self.new
      @app.run
    end

    def stop
      Curses.close_screen
    end
  end
end

begin
  SnakeGame.run
rescue StandardError => e
  SnakeGame.stop
end

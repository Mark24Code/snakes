#!/usr/bin/env ruby

require "curses"

Curses.init_screen
Curses.cbreak
Curses.noecho
Curses.curs_set(0)  # Invisible cursor
Curses.stdscr.keypad = true

exit_game = lambda do
  SnakeGame.stop
  puts "Good Bye! :D"
  exit 130
end

trap("INT"){ exit_game.call }
at_exit { exit_game.call }



class SnakeGame
  def initialize
    @game_speed = 20
    @game_update_time = 1.0 / @game_speed

    @non_block_timeout = 0.001

    @frame = nil
    @board = nil

    @window_width = nil
    @window_height = nil

    @board_width = nil
    @board_height = nil

    @pause = false
    @game_status = :RUN # :RUN ,:PAUSE, :GAME_OVER

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

    @board = @frame.subwin(@board_height,@board_width,1,1)
    @board.keypad = true
    @board.timeout = @non_block_timeout

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


  def inc_speed
    speed = @game_speed + 1
    if speed >= 30
      @game_speed = 30
    else
      @game_speed = speed
    end
  
    @game_update_time = 1.0 / @game_speed
  end

  def dec_speed
    speed = @game_speed - 1
    if speed <= 5
      @game_speed = 5
    else
      @game_speed = speed
    end

    @game_update_time = 1.0 / @game_speed
  end

  def render_game_info
    # Press Key
    @info_board.setpos(1, 1)
    @info_board.addstr("[Press]: #{@current_direction.to_s}")

    # score
    @info_board.setpos(3, 1)
    @info_board.addstr("[Score]: #{@score}")

    # speed
    @info_board.setpos(5, 1)
    @info_board.addstr("[Speed]: #{@game_speed}")

    # tick time
    @info_board.setpos(7, 1)
    @info_board.addstr("[Tick]: #{@game_update_time}")

    # status
    @info_board.setpos(9, 1)
    @info_board.addstr("[Status]: #{@game_status}")
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

  def check_game(next_point)
    if @snake.include?(next_point)
      @game_status = :GAME_OVER
      return false
    end

    next_y, next_x = next_point

    if !(next_x > 0 && next_x < @board_width && next_y > 0 && next_y < @board_height)
      @game_status = :GAME_OVER
      return false
    end

    return true
    
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

    next_point = [head_y, head_x]

    result = self.check_game(next_point)
    if result
      @snake.unshift(next_point)
      @snake.pop
    end
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
      elsif c == Curses::KEY_BACKSPACE || c == 'p'
        @game_status = @game_status == :PAUSE ? :RUN : :PAUSE
      elsif c == 'm'
        self.inc_speed
      elsif c == 'n'
        self.dec_speed
      else
        return # 这里其实断掉了。其实接住了外循环，每次读取数据
      end
    end
  end

  def reset_game
    self.initialize
  end

  def main_loop
    loop do
      self.init_game_board
      self.reset_game
      game_result = catch(:end_game) do
        while @game_status != :GAME_OVER do
          self._event_listener
          
          @board.clear
          @info_board.clear
          @board.box(0, 0)
          @info_board.box(0, 0)
  
          if @game_status == :RUN
            self.add_step
          end
          self.render_food  
          self.render_snake
          self.check_game
          self.render_game_info
    
          @board.refresh
          @info_board.refresh
          sleep @game_update_time
        end
  
        throw :end_game, :GAME_OVER
      end
      
      next_status = catch(:next_action) do
        if game_result == :GAME_OVER
          @board.timeout = -1
          @board.clear
          @board.box(0,0)
          @board.setpos(@board_height/2, @board_width/2 - 10)
          @board.addstr("GAME OVER")
          @board.setpos(@board_height/2 + 2, @board_width/2 - 10)
          @board.addstr("Play Again?")
          @board.setpos(@board_height/2 + 3, @board_width/2 - 10)
          @board.addstr("Y:Yes/ N: Exit")
          @board.refresh
          @board.timeout = -1

          next_goto = @board.getch

          # throw :next_action, :RUN
          next_goto = nil
          while next_goto != 'y'
            next_goto = @board.getch
            if next_goto == 'n'
              exit 0
            elsif next_goto == 'y'
              @board.setpos(@board_height/2 + 4, @board_width/2 - 10)
              @board.addstr(next_goto)
              @board.refresh
    
              throw :next_action, :RUN
            end
          end
        end
      end

      @game_status = next_status
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
  puts e
  exit -1
end


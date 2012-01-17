class TopicWall

  attr_accessor :blocks, :tags, :total_block_weight, :total_tags, :grid, :grid_width, :unit_width, :unit_height

  # Here are the different block sizes, weights, and colors
  @@BLOCKS = [
    [:weight => 2000, :width => 1, :height => 1, :color => :aqua],
    [:weight => 700, :width => 2, :height => 2, :color => :coral],
    [:weight => 300, :width => 4, :height => 4, :color => :blue],
    [:weight => 250, :width => 4, :height => 6, :color => :fuchsia],
    [:weight => 250, :width => 6, :height => 7, :color => :navy],
    [:weight => 200, :width => 8, :height => 8, :color => :green],
    [:weight => 100, :width => 10, :height => 12, :color => :lime],
    [:weight => 50, :width => 14, :height => 14, :color => :maroon]
  ]

  def initialize
    self.blocks = []
    self.tags = []

    # This is the grid width in units. In pixels the width would be UNIT_WIDTH * GRID_WIDTH
    self.grid_width = 41

    # Here we define the pixel width and height of a unit
    self.unit_width = 25
    self.unit_height = 25
  end

  def foo
    "foo"
  end

  def test_tags
    test_tags = []
    10.times do |two|
      (1..10).each do |three|
        test_tags << [:name => "#{three.to_s}", :score => three*10]
      end
    end
    test_tags
  end

  def initialize_blocks
    @@BLOCKS.each do |block|
      blocks << TopicWallBlock.new(block)
    end
  end

  def set_tags(new_tags)
    new_tags.each do |tag|
      tags << TopicWallTag.new(tag)
    end
  end

  def compute
    # Create the block objects
    initialize_blocks

    # Get aggregates
    total_block_weight = 0
    blocks.each {|b| total_block_weight += b.weight}
    total_tags = tags.length

    # Sort tags by score
    tags.sort_by {|t| t.score*-1}

    # Sort blocks by weight
    blocks.sort_by {|b| b.area*-1}

    # Assign tags to a block
    block_index = 0
    tags.each do |t|
      block = blocks[block_index]
      block.add_tag(t)
      if block.tags.length >= total_tags * block.weight / total_block_weight
        block_index += 1 if blocks[block_index+1]
      end
    end

    # Shuffle the tags
    tags.replace tags.sort_by{ rand }

    # Assign tags to a position in the grid
    self.grid = TopicWallGrid.new
    tags.each do |t|
      # The following block of code looks up the first position
      # we should use to begin looking for a place for this tag, based
      # on the last location a tag with the same block was assigned.
      # This prevents looking through the beginning of the grid (which is presumably fairly full by now)
      # unnecessarily.
      if t.block.min_position
        start_y = t.block.min_position.y
        start_x = t.block.min_position.x
      else
        start_y = 1
        start_x = 1
      end

      y = start_y

      # Loop through each row
      count = 0
      until t.position || count > 50
        # Loop through each column
        x = start_x
        (x..self.grid_width).each do |w|
          if grid.tag_will_fit_here(t, w, y)
            grid.add_tag(t, w, y)
            t.block.min_position = TopicWallPosition.new(w+t.block.width, y)
            break 2
          end
        end
        count += 1
      end
    end

  end

end

class TopicWallBlock
  attr_accessor :weight, :width, :height, :color, :min_position, :min_diagonal, :tags

  def initialize(block)
    self.min_diagonal = 1
    self.min_position = nil
    self.tags = []
    self.weight = block[0][:weight]
    self.width = block[0][:width]
    self.height = block[0][:height]
    self.color = block[0][:color]
  end

  def add_tag(tag)
    tags << tag
    tag.block = self
  end

  def area
    width * height
  end
end

class TopicWallTag
  attr_accessor :block, :score, :name, :position

  def initialize(tag)
    self.score = tag[0][:score]
    self.name = tag[0][:name]
    self.position = nil
  end

  def positions_needed(x,y)
    positions_needed = []
    width = x + block.width
    height = y + block.height
    horizontal = x
    until horizontal >= width
      positions_needed[horizontal] ||= []
      vertical = y
      until vertical >= height
        positions_needed[horizontal][vertical] = true
        vertical += 1
      end
      horizontal += 1
    end

    positions_needed
  end
end

class TopicWallGrid
  attr_accessor :tags, :positions_used

  def initialize
    self.tags = []
    self.positions_used = []
  end

  def tag_will_fit_here(tag,x,y)
    positions_needed = tag.positions_needed(x,y)
    intersection = false
    positions_needed.each_with_index do |rows, column|
      next unless column && rows
      if positions_used[column]
        rows.each_with_index do |value, row|
          next unless row
          if positions_used[column][row]
            intersection = true
            break 2
          end
        end
      end
    end

    if intersection
      false
    else
      true
    end
  end

  def add_tag(tag,x,y)
    tag.position = TopicWallPosition.new(x,y)
    tags << tag
    positions_needed = tag.positions_needed(x,y)
    positions_needed.each_with_index do |rows, column|
      next unless rows
      positions_used[column] ||= []
      rows.each_with_index do |value, row|
        next unless row && value
        positions_used[column][row] = true
      end
    end
  end
end

class TopicWallPosition
  attr_accessor :x, :y

  def initialize(x,y)
    if x > TopicWall.new.grid_width
      self.x = 1
      self.y = y+1
    else
      self.x = x
      self.y = y
    end
  end

  def to_s
    "#{x}x#{y}"
  end
end
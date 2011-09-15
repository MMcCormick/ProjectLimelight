module ImageHelper
  def default_image(object, dimensions, classes='', id='')
    image_tag object.default_image("d#{dimensions[0]}_#{dimensions[0]}"), :width => "#{dimensions[0]}px", :height => "#{dimensions[1]}"
  end
end

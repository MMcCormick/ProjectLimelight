if defined?(Footnotes) && Rails.env.development?
  Footnotes.run! # first of all
  Footnotes::Filter.notes -= [:cookies, :session]
  #Footnotes::Notes::AssignsNote.ignored_assigns += [:@_view_renderer, :@_response_body, :@_routes, :@_view_context_class]
end
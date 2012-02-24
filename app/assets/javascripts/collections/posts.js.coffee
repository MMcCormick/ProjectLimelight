class LL.Collections.Posts extends Backbone.Collection
  url: '/api/posts'
  model: LL.Models.Post

  parse: (resp, xhr) ->
    _(resp).map (attrs) ->
      switch attrs.type
        when 'Talk' then new LL.Models.Talk attrs
        when 'Link' then new LL.Models.Link attrs
        when 'Picture' then new LL.Models.Picture attrs
        when 'Video' then new LL.Models.Video attrs
        # should probably add an 'else' here so there's a default if,
        # say, no attrs are provided to a Logbooks.create call
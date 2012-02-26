class LL.Collections.Posts extends Backbone.Collection
  model: LL.Models.Post

  findOrCreate: (id, data=null) ->
    model = @get(id)

    # set it to data if we're passing in a model
    model = data unless model

    unless model
      model = new LL.Models.Post
      model.fetch({data: {id: id}})
      @add(model)

    model

  parse: (resp, xhr) ->
    _(resp).map (attrs) ->
      switch attrs.type
        when 'Talk' then new LL.Models.Talk attrs
        when 'Link' then new LL.Models.Link attrs
        when 'Picture' then new LL.Models.Picture attrs
        when 'Video' then new LL.Models.Video attrs
        # should probably add an 'else' here so there's a default if,
        # say, no attrs are provided to a Logbooks.create call
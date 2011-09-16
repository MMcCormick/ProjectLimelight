// Topic tagger, currently unused

function topic_tagger (n) {
  this.numTags = n;
  this.tags = new Array();
  this.add = function (tag) {

    this.tags.push(tag);
  }
}

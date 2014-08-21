# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/





$(document).on 'click', '.reply', (event) ->
  
  form = $(this).parent().parent().find(".comment_reply:first").show();
  parent_id = $(this).data("parent_id")
  form.html($(".comment_form").clone().removeClass("comment_form").append($('<input>').attr({ type: 'hidden', id: "parent_id", value: parent_id , name: "parent_id" })));
  event.preventDefault()


$(document).on 'click', '.toggle_comment', (event) ->
  if($(this).html() == "-")
    $(this).html("+");
    $(this).closest(".comment").find(".comment_contents").first().slideUp(0);
  else
    $(this).html("-");
    $(this).closest(".comment").find(".comment_contents").first().slideDown(0);

  event.preventDefault()

$(document).on 'click', '.add_tag', (event) ->
  $(".tag_form").slideDown(0);
  event.preventDefault();

$(document).on 'click', '.add_workflow', (event) ->
  $(".workflow_form").slideDown(0);
  event.preventDefault();

  
$(document).on 'click', '.edit_assignee', (event) ->
  $("#assignee_value").hide();
  $("#assignee_select").show();
  event.preventDefault();


$(document).on 'click', '.add_attachment', (event) ->
  $(".attachment_form").slideDown(0);
  event.preventDefault();
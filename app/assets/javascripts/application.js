// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require jquery_sparklines

//= require foundation
// require foundation_datatables
//= require foundation_datepicker
//= require results
//= require searches
//= require select2
//= require d3
//= require sonic
//= require nvd3.min
// require active_scaffold
// require turbolinks

//= require_self









// function header_color
// {

//   colors = [0x162963, 0x2E556E, 0xFF5701 0x1C688A, 0x7A99C8, 0x4371AD, 0x3C6BCD, 0x162963]
//   boundaries = [0,5,8,12,13,17,21]

//   new Date.getHours()
//   t = new Date()

//   for (i = 1; i < boundaries.length; i++) { 
//     hour = t.getHours()
//     if(hour < boundaries[i])
//     {

//     }

//   } 

//  }






this.SearchStatusPoller = {
  poll: function(force_poll) {
    if(typeof force_poll !== 'undefined' && force_poll)
    {
      return setTimeout(this.request, 0);
    }
    else
    {
      return setTimeout(this.request, 5000);
    }

  },
  request: function() {
    return $.get($('#status_notifications').data('url'), {
      after: $('.status').last().data('id')
    });
  },
  addStatuses: function(statuses) {
    if (statuses.length > 0) {
      $('#status_notifications').html($(statuses));
    }
    return this.poll();
  }
};

var create_preloader = function()
{
  $("#preloader-modal").remove();
  $("body").append('<div id="preloader-modal" style="height:500px" class="reveal-modal" data-reveal><h2 class="centered">Loading...</h1><div class="preloader" ></div></div>')
  $("#preloader-modal").foundation('reveal','open')
  show_preloader();
}


var hide_preloader = function()
{


  //Insert small delay to ensure modal has had enough time to open--otherwise the modal will not close
  setTimeout( 
    function()
    {
      preloader.stop()
      $(".preloader").html("")
      $(".preloader").hide();
      $("#preloader-modal").foundation('reveal','close')
    }, 500)
}


var preloader = null



var show_preloader = function()
{
  
  //Preloader

  var preloader_config = {

    width: 100,
    height: 100,

    stepsPerFrame: 1,
    trailLength: 1,
    pointDistance: .025,

    strokeColor: '#05E2FF',

    fps: 20,

    setup: function() {
      this._.lineWidth = 2;
    },
    step: function(point, index) {

      var cx = this.padding + 50,
        cy = this.padding + 50,
        _ = this._,
        angle = (Math.PI/180) * (point.progress * 360);

      this._.globalAlpha = Math.max(.5, this.alpha);

      _.beginPath();
      _.moveTo(point.x, point.y);
      _.lineTo(
        (Math.cos(angle) * 35) + cx,
        (Math.sin(angle) * 35) + cy
      );
      _.closePath();
      _.stroke();

      _.beginPath();
      _.moveTo(
        (Math.cos(-angle) * 32) + cx,
        (Math.sin(-angle) * 32) + cy
      );
      _.lineTo(
        (Math.cos(-angle) * 27) + cx,
        (Math.sin(-angle) * 27) + cy
      );
      _.closePath();
      _.stroke();

    },
    path: [
      ['arc', 50, 50, 40, 0, 360]
    ]
  }

  preloader = new Sonic(preloader_config)

  $(".preloader").append(preloader.canvas)
  
  preloader.canvas.style.marginTop = "100px"
  preloader.canvas.style.marginLeft = "50%"
  preloader.canvas.style.position = "relative"
  preloader.canvas.style.left = "-50px"

  preloader.play();
  $(".preloader").show();


}


var ready = function(){
  
  $('.datepicker').fdatepicker()
  


  //header_color();
  




  //Setup foundation
  $(document).foundation();

  //Setup sparklines
  
 $('.sparkline').sparkline('html', {
    type: 'line',
    width: '100px',
    lineColor: '#074e68',
    fillColor: undefined,
    spotRadius: 0,
    

  }); 


  //Load default select2 boxes
  $(".select2").select2();
  $(".select2").removeClass("select2");


  //Load custom select2 boxes
  $(".remote_select2").each(function() {
    //alert( this.attr("data-path"));
    var context_object = this
    $(this).select2({
        placeholder: "Please choose",
        minimumInputLength: 0,
        multiple: $(context_object).attr("data-multiple") != undefined,
        
        ajax: {
            url: function() {return this.attr("data-path") },
            dataType: 'json',
            quietMillis: 300,

            data: function (search, page) {
                return {
                    q: search,
                    per_page: 25,
                    page: page,
                };
            },
            
            results: function (data, page) {

              var more = (page * 25) < data.meta.total; // whether or not there are more results available
              // notice we return the value of more so Select2 knows if more results can be loaded
              
              return {results: data[$(context_object).attr("data-object")], more: more};
            }
            
            
        },
        createSearchChoice:function(term, data) { 
            if($(context_object).attr("data-create-new"))
            {
              if ($(data).filter(function() {
              return term.localeCompare(this.text)===0; 
              }).length===0) 
              {
                
                d = {}
                  d[$(context_object).attr("data-attribute")] = term
                if($(context_object).attr("data-id-attribute") != undefined)
                  d[$(context_object).attr("data-id-attribute")] = term
                else
                  d.id = term

                return d
              }
            }
            return [] 
          },
        tokenSeparators: [","],
        escapeMarkup: function (markup) {
            var replace_map = {
                '\\': '&#92;',
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&apos;',
                "/": '&#47;'
            };

            return String(markup).replace(/[&<>"'/\\]/g, function (match) {
                    return replace_map[match[0]];
            });

            return markup;
          },
        formatResult: function (item) { return this.escapeMarkup(item[$(context_object).attr("data-attribute")]); },     


        formatSelection: function (item) {  return this.escapeMarkup(item[$(context_object).attr("data-attribute")]); }, 
        initSelection: function (element, callback) {


            var data = [];
            if($(context_object).attr("data-initial") != undefined && $(context_object).attr("data-initial") != "placeholder_value")
            {
              data = $(context_object).data("initial")
              $(context_object).attr("value", JSON.stringify(data))
              callback(data);
              
            }
            else if($(context_object).attr("data-parse-initial") != undefined)
            {
              $(element.val().split(",")).each(function () {
              
                d = {}
                d[$(context_object).attr("data-attribute")] = this
                if($(context_object).attr("data-id-attribute") != undefined)
                  d[$(context_object).attr("data-id-attribute")] = this
                else
                  d.id = this



                data.push(d);
              });
            
            callback(data);
            
          }

        },
        id: function (item) {  
          if($(context_object).attr("data-id-attribute") != undefined) 
          {
            if($(context_object).attr("data-id-attribute") == "self" && item.length != 0)
            {
              return JSON.stringify(item);
            }

            return  item[$(context_object).attr("data-id-attribute")]; 
          }
          else
          {
            return item.id;
          }
        }   

    });
    $(".remote_select2").on('change', function(e) {
      if($(this).attr("data-autosubmit") == 'true') 
      {
        $(this).parent().submit()
      }

    });
  });

  //Remove the class so this is only classed once...
  $(".remote_select2").removeClass("remote_select2");
  $(".remote_select2").css("display", "")

  //Poll for events
  SearchStatusPoller.poll(true);


  //Actions for hidden fields
  $('.hidden').hide();
  $('.reveal-hidden').mouseover(function() { $(this).find(".hidden").show() });
  $('.reveal-hidden').mouseout(function() {$(this).find(".hidden").hide() } );


  

  $('.preload-form').click(function() { 
    create_preloader();
  })

  $('.preload').click(function() { 
    show_preloader();
  })
  

  $('.close-modal').click(function() { 
      $(".reveal-modal").foundation('reveal','close')
  })

  //Actions for index checkboxes
  $('#check_all_results').click(function() { 
      if($(this).is(':checked'))
      {
        $('.result_checkbox').prop('checked', true);
        $('.result_checkbox').prop('disabled', false);
        $('#update_all_from_query_link').slideDown();
        $('#update_all_from_query').val(false);

        $('#update_all_from_page_header').slideUp();
        $('#update_all_from_page_header').slideDown();
      } 
      else
      {
        $('.result_checkbox').prop('checked', false);
        $('.result_checkbox').prop('disabled', false);
        $('#update_all_from_query').val(false);
        $('#update_all_from_page_header').slideUp();
        $('#update_all_from_query_header').slideUp();

      }
      if($(".result_checkbox:checked").length > 0)
      {
          $("#result_action_panel").slideDown();
      }
      else
      {
         $("#result_action_panel").slideUp();
      }
    
   });

  $('#update_all_from_query_link').click(function() { 
    $('#update_all_from_query').val(true);
    $('.result_checkbox').prop('disabled', true);
    $('#update_all_from_query_header').slideDown();
    $('#update_all_from_page_header').slideUp();
    if($(".result_checkbox:checked").length > 0)
    {
        $("#result_action_panel").slideDown();
    }
    else
    {
       $("#result_action_panel").slideUp();
    }
  });

  $('#clear_selection').click(function() { 
    $('#update_all_from_query').val(false);
    $('#update_all_from_query_header').slideUp();
    $('#update_all_from_page_header').slideUp();
    $('.result_checkbox').prop('checked', false);
    $('.result_checkbox').prop('disabled', false);
    $('#check_all_results').prop('checked', false);
    $("#result_action_panel").slideUp();
  });

  $('.result_checkbox').click(function()
  {
    $('#check_all_results').prop('checked', false);
    $('#update_all_from_query').val(false);
    $('#update_all_from_query_header').slideUp();
    $('#update_all_from_page_header').slideUp();
    
    if($(".result_checkbox:checked").length > 0)
    {
        $("#result_action_panel").slideDown();
    }
    else
    {
       $("#result_action_panel").slideUp();
    }
  })

  $('.update_multiple_button').click(function(e) { 
    if(!e.isDefaultPrevented())
    {
      $('#update_results_form').append($("#results_table").find("input").clone(true,true).hide())
    }    
  })


  //Lightboxes
  $('.open_lightbox').click(function() { 
    $($(this).parent().find("img")[1]).trigger("click")
  })


  //Split buttons
  $('.split_button_submit').click(function(e) { 
    if(!e.isDefaultPrevented())
    {
      $(this).after($('<input />')
        .attr('id', 'commit')
        .attr('name', 'commit')
        .attr('type', 'hidden')
        .attr('value', this.text))

      $(this).closest("form").submit();
    }
  })

    $('.split_button_submit > span').click(function(e) { 
    e.preventDefault();
    
  })

  
  
};


$(document).ready(ready);

